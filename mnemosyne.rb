#!/usr/bin/env ruby

# This is the wrapper / glue for Mnemosyne.
# Mnemosyne manages AWS backups.
#
# Lovingly hand-crafted by: Jonathan Gnagy <jgnagy@intellisis.com>

require 'rubygems'
require 'bundler/setup'

require 'yaml'
require 'colorize'
require 'aws-sdk'

# Either load the config from a specific location, or look in "." for config.yml
@config_file = if ARGV[0]
  ARGV[0]
else
  './config.yml'
end

begin
  Config = YAML.load_file(@config_file)
rescue => e
  puts "Unable to load config from #{@config_file}:".red
  fail e
end

@rds_client = Aws::RDS::Client.new(region: Config['region'])
@ec2_client = Aws::EC2::Client.new(region: Config['region'])

def backup_instance_rds(instance)
  # Create a DB snapshot
  snap_id = "#{instance['rds']['instance']}-#{Time.now.strftime('%Y%m%d-%H%M%S')}"
  puts ">> Creating RDS Snapshot #{snap_id}".green
  @rds_client.create_db_snapshot(
    db_instance_identifier: instance['rds']['instance'],
    db_snapshot_identifier: snap_id
  )
  
  # Gather all the snapshots we know of for this RDS instance
  snaps = @rds_client.describe_db_snapshots(
    db_instance_identifier: instance['rds']['instance']
  ).db_snapshots
  
  # isolate snapshots older than our max (set via the config)
  to_remove = (snaps - snaps.last(instance['rds']['max_backups'])).collect do |s|
    s.db_snapshot_identifier
  end

  # Delete the old snapshots
  to_remove.each do |snap|
    puts ">> Deleting RDS Snapshot #{snap}...".red
    @rds_client.delete_db_snapshot(db_snapshot_identifier: snap)
  end
end

def backup_instance(instance)
  name = instance.key?('name') ? instance['name'] : instance['id']
  image_id = "#{name}-#{Time.now.strftime('%Y%m%d-%H%M%S')}"
  reboot = instance.key?('reboot') ? instance['reboot'] : false
  puts ">> Creating EC2 AMI #{image_id}".green
  new_ami_id = @ec2_client.create_image(
    instance_id: instance['id'],
    name: image_id,
    description: "Mnemosyne backup of #{name}",
    no_reboot: reboot ? false : true
  )

  # Tag the new AMI so we can retrieve it later
  @ec2_client.create_tags(resources: [new_ami_id.image_id], tags: [{key: "MnemosyneName", value: name}])

  # Look up AMIs with our tag
  amis = @ec2_client.describe_images(filters: [
    {name: 'tag:MnemosyneName', values: [name]},
    {name: 'state', values: ['available']}
  ]).images

  # isolate AMIs older than our max (set via the config)
  to_remove = (amis - amis.last(instance['max_backups'])).collect do |a|
    a.image_id
  end

  # Deregister (delete) the old AMIs
  to_remove.each do |old_ami|
    puts ">> Deregistering AMI #{old_ami}...".red
    @ec2_client.deregister_image(image_id: old_ami)
  end

  # Look through all snapshots, narrowing down to just those created by AMI process for this instance
  ami_ebs_snaps = @ec2_client.describe_snapshots.snapshots.collect do |snap|
    snap if snap.description.match /CreateImage\(#{instance['id']}\)/
  end.compact

  # Look up current AMIs with our tag (after some deregistrations)
  current_amis = @ec2_client.describe_images(filters: [
    {name: 'tag:MnemosyneName', values: [name]},
    {name: 'state', values: ['available']}
  ]).images

  # only delete non-current EBS snapsnots
  current_amis.map(&:image_id).each do |ami|
    ami_ebs_snaps.delete_if {|snap| snap.description.match /#{ami}/ }
  end

  # Remove the old snapshots
  ami_ebs_snaps.each do |snapshot|
    puts ">> Deleting Snapshot #{snapshot.snapshot_id}...".red
    @ec2_client.delete_snapshot(snapshot_id: snapshot.snapshot_id)
  end
end

Config['instances'].each do |instance|
  # Do RDS stuff if we're supposed to
  if instance.key? 'rds'
    backup_instance_rds instance
  end

  backup_instance instance
end

puts "> All finished!".green.bold
