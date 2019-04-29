module SprinkleDNS
  MockChangeRequest = Struct.new(:hosted_zone, :tries, :tries_needed, :in_sync)

  class MockClient
    attr_reader :hosted_zones

    def initialize(hosted_zones)
      @hosted_zones = hosted_zones
    end

    def fetch_hosted_zones(filter: [])
      hosted_zones = []

      if filter.empty?
        return []
      end

      @hosted_zones.each do |hz|
        hz.resource_record_sets.each do |entry|
          entry.persisted!
        end
      end

      hosted_zones = @hosted_zones.select{|hz| filter.include?(hz.name)}

      if hosted_zones.size != filter.size
        missing_hosted_zones = (filter - hosted_zones.map(&:name)).join(',')
        raise MissingHostedZones, "Whooops, the following hosted zones does not exist: #{missing_hosted_zones}"
      end

      hosted_zones
    end

    def change_hosted_zones(hosted_zones)
      change_requests = []

      hosted_zones.each do |hosted_zone|
        if hosted_zone.compile_change_batch.any?
          change_requests << MockChangeRequest.new(hosted_zone, 1, rand(3..15), false)
        else
          change_requests << MockChangeRequest.new(hosted_zone, 1, 1, true)
        end
      end

      change_requests
    end

    def check_change_requests(change_requests)
      change_requests.reject{|cr| cr.in_sync}.each do |change_request|
        change_request.tries += 1
        change_request.in_sync = change_request.tries >= change_request.tries_needed
      end

      change_requests
    end
  end
end
