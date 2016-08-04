module Mnemosyne
  module Clients
    class RDS
      include Singleton

      # Used to wrap actual API actions with some sanity checks, etc.
      def action
        load_client
        count_action
        # Increment our sleep counter aggressively based on the number of transactions
        sleep(@action_counter / 100.0)
        # The yield must be last!
        yield @aws_client
      end

      private

      # Make sure we have a working API client
      def load_client
        @aws_client ||= Aws::RDS::Client.new(region: Mnemosyne.config.region)
      end

      # Not thread-safe!
      def count_action
        @action_counter ||= 1
        @action_counter = @action_counter + 1
      end

    end
  end
end
