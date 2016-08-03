module Mnemosyne
  module Resources
    class EC2Instance
      attr_accessor :max_backups, :name

      def initialize(identifier, name, max_backups, reboot = false)
        @identifier = identifier
        @name = name
        @max_backups = max_backups
        @reboot = reboot
      end

      def reboot?
        @reboot
      end

      # Override #id() with the AWS instance identifier
      def id
        @identifier.dup
      end

      # Grab a reference to the EC2 Client singleton
      def aws_client
        Mnemosyne::Clients::EC2.instance
      end

      def amis
        aws_client.action do |client|
          client.describe_images(filters: [
            {name: 'tag:MnemosyneName', values: [@name]},
            {name: 'state', values: ['available']}
          ]).images.sort {|a,b| a.creation_date <=> b.creation_date }
        end
      end

      def ebs_snapshots(options = {})
        regex = 'CreateImage\(' + id + '\)'
        regex << " for #{options[:ami]}" if options.key?(:ami)
        
        snaps = aws_client.action do |client|
          client.describe_snapshots.snapshots.collect do |snap|
            snap if snap.description.match Regexp.new(regex)
          end.compact.sort {|a,b| a.start_time <=> b.start_time }
        end

        if options.key?(:exclude)
          [*options[:exclude]].each do |exclusion|
            snaps.delete_if {|snap| snap.description.match Regexp.new(exclusion) }
          end
        end
        return snaps
      end

      def create_ami(options = {})
        aws_client.action do |client|
          puts ">> Creating EC2 AMI #{@name}".green if options[:verbose]
          new_ami = client.create_image(
            instance_id: id,
            name: "#{@name}-#{Time.now.strftime('%Y%m%d-%H%M%S')}",
            description: "Mnemosyne backup of #{@name}",
            no_reboot: @reboot ? false : true
          )
          
          # Tag the new AMI so we can retrieve it later
          client.create_tags(
            resources: [new_ami.image_id], tags: [{key: "MnemosyneName", value: @name}]
          )
        end
      end

      def delete_ebs_snapshot(identifier, options = {})
        aws_client.action do |client|
          puts ">> Deleting Snapshot #{identifier}...".red if options[:verbose]
          client.delete_snapshot(snapshot_id: identifier)
        end
      end

      def deregister_ami(identifier, options = {})
        aws_client.action do |client|
          puts ">> Deregistering AMI #{identifier}...".red if options[:verbose]
          client.deregister_image(image_id: identifier)
        end
      end

      # Delete all but the most recent @max_backups count of AMIs
      def cleanup_amis(options = {})
        # take the sorted array and remove the most recent AMIs, then delete what's left
        list = amis
        (list - list.last(@max_backups)).map(&:image_id).each do |ami|
          deregister_ami(ami, options)
        end
      end

      # Delete all EBS snapshots for this instance, other than those in use by our recent AMIs
      def cleanup_ebs_snapshots(options = {})
        ebs_snapshots(exclude: amis.map(&:image_id)).each do |snapshot|
          # Only delete snapshots older than 48 hours...
          if (snapshot.start_time + 48 * 60 * 60 ) < Time.now
            delete_ebs_snapshot(snapshot.snapshot_id, options)
          else
            puts ">>> Not Deleting Snapshot #{snapshot.snapshot_id} based on age...".yellow if options[:verbose]
          end
        end
      end

    end
  end
end
