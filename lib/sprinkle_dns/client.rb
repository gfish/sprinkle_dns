require 'sprinkle_dns/zone_domain'
require 'sprinkle_dns/zone_entry'
require 'sprinkle_dns/core_ext'
require 'sprinkle_dns/providers/aws_dns'

module SprinkleDNS
  class Client

    attr_reader :hosted_zones

    def initialize(aws_access_key_id, aws_secret_access_key)
      @hosted_zones           = {}
      @aws_access_key_id      = aws_access_key_id
      @aws_secret_access_key  = aws_secret_access_key
    end

    def entry(type, name, value, ttl = 3600)
      zone_domain = ZoneDomain::parse(name)
      init_hosted_zone(zone_domain)

      if ['CNAME', 'MX'].include?(type)
        value = Array.wrap(value)

        value.map!{|v| zonify(v)}
      end

      @hosted_zones[zone_domain] << ZoneEntry.new(type, zonify(name), Array.wrap(value), ttl.to_s)
    end

    def sprinkle!
      wanted_zones = self.hosted_zones

      # 1. Make sure all self.hosted_zones exists at AWS
      # 2. DIFF AWS.hosted_zones versus self.hosted_zones
      # 3. Show the diff nicely
      # 4. Push all changes to AWS
      # 5. WIN
    end

   private

    def zonify(name)
      if name.end_with?('.')
        name
      else
        "#{name}."
      end
    end

    def init_hosted_zone(zone_domain)
      @hosted_zones[zone_domain] = [] if @hosted_zones[zone_domain].nil?
    end
  end

end
