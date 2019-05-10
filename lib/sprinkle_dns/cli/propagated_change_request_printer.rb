module SprinkleDNS::CLI
  class PropagatedChangeRequestPrinter
    def initialize
      reset!
    end

    def reset!
      @completed = []
      @printed = []
    end

    def draw(change_requests, sync_word = "SYNCING", synced_word = "SYNCED")
      change_requests.each do |change_request|
        if change_request.in_sync
          hosted_zone_name = change_request.hosted_zone.name

          unless @completed.include?(hosted_zone_name)
            @completed << hosted_zone_name + '.' * change_request.tries
          end
        end
      end

      @completed.each do |complete|
        unless @printed.include?(complete)
          puts "#{complete}.. #{synced_word}!"
          @printed << complete
        end
      end

      sleep(2)
    end
  end
end
