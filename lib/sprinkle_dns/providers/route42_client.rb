module SprinkleDNS
  # Route53ChangeRequest = Struct.new(:hosted_zone, :change_info_id, :tries, :in_sync)

  class Route42Client
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

  end
end
