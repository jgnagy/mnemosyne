#!/usr/bin/env ruby

# This is the wrapper / glue for Mnemosyne.
# Mnemosyne manages AWS backups.
#
# Lovingly hand-crafted by: Jonathan Gnagy <jgnagy@intellisis.com>

require 'yaml'
require 'colorize'
require 'aws-sdk'

Config = YAML.load_file('./config.yml')

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
  @ec2_client.create_image(
    instance_id: instance['id'],
    name: image_id,
    description: "Mnemosyne backup of #{name}",
    no_reboot: reboot ? false : true
  )
end

Config['instances'].each do |instance|
  # Do RDS stuff if we're supposed to
  if instance.key? 'rds'
    backup_instance_rds instance
  end

  backup_instance instance
end

puts "> All finished!".green.bold
