module SprinkleDNS
  MockChangeRequest = Struct.new(:hosted_zone, :tries, :tries_needed, :in_sync)

  class MockClient
    attr_reader :hosted_zones

    def initialize(hosted_zones = [])
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

      @hosted_zones.select{|hz| filter.include?(hz.name)}
    end

    def create_hosted_zones(hosted_zones)
      change_requests = []

      hosted_zones.each do |hosted_zone|
        change_requests << MockChangeRequest.new(hosted_zone, 0, rand(3..15), false)
      end

      change_requests
    end

    def change_hosted_zones(hosted_zones, configuration)
      change_requests = []

      hosted_zones.each do |hosted_zone|
        changes = EntryPolicyService.new(hosted_zone, configuration).compile

        if changes.any?
        else
          change_requests << MockChangeRequest.new(hosted_zone, 1, 1, true)
          change_requests << MockChangeRequest.new(hosted_zone, 0, rand(3..15), false)
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
