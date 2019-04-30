module SprinkleDNS::CLI
  class PropagatedChangeRequestPrinter
    def initialize
      @completed = []
      @printed = []
    end

    def draw(change_requests)
      change_requests.each do |change_request|
        if change_request.in_sync
          hosted_zone_name = change_request.hosted_zone.name

          unless @completed.include?(hosted_zone_name)
            @completed << hosted_zone_name
          end
        end
      end

      @completed.each do |complete|
        unless @printed.include?(complete)
          puts "#{complete}.. DONE!"
          @printed << complete
        end
      end

      sleep(2)
    end
  end
end
