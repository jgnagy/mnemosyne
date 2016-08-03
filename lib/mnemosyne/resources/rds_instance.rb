module Mnemosyne
  module Resources
    class RDSInstance
      attr_accessor :max_backups

      def initialize(identifier, max_backups)
        @identifier = identifier
        @max_backups = max_backups
      end

      # Override #id() with the AWS instance identifier
      def id
        @identifier.dup
      end

      # Grab a reference to the RDS Client singleton
      def aws_client
        Mnemosyne::Clients::RDS.instance
      end

      # A chronologically sorted array of all RDS snapshots for the RDS instance
      def snapshots
        aws_client.action do |client|
          snaps = client.describe_db_snapshots(
            db_instance_identifier: id
          ).db_snapshots
          snaps.delete_if {|snap| snap.status != 'available' }
          snaps.sort {|a,b| a.snapshot_create_time <=> b.snapshot_create_time }
        end
      end

      # Create a snapshot of this RDS instance
      def create_snapshot(options = {})
        # If no name is specified, use a simple timestamp appended to the instance identifier
        name = options.key?(:name) ? options[:name] : "#{id}-#{Time.now.strftime('%Y%m%d-%H%M%S')}"
        
        aws_client.action do |client|
          # Output some text if we're being verbose
          puts ">> Creating RDS Snapshot #{name}".green if options[:verbose]
          client.create_db_snapshot(
            db_instance_identifier: id,
            db_snapshot_identifier: name
          )
        end
      end

      # Delete a specific RDS snapshot based on its identifier
      def delete_snapshot(name, options = {})
        aws_client.action do |client|
          # Output some text if we're being verbose
          puts ">> Deleting RDS Snapshot #{name}...".red if options[:verbose]
          client.delete_db_snapshot(db_snapshot_identifier: name)
        end
      end

      # Delete all but the most recent @max_backups count of snapshots
      def cleanup_snapshots(options = {})
        # take the sorted array and remove the most recent snapshots, then delete what's left
        (snapshots - snapshots.last(@max_backups)).map(&:db_snapshot_identifier).each do |snap|
          delete_snapshot(snap, options)
        end
      end

    end
  end
end
