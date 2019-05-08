module SprinkleDNS::CLI
  class PropagatedChangeRequestPrinter
    def initialize
      @completed = []
      @printed = []
    end

    def draw(sync_word, synced_word, change_requests)
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
