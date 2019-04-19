require 'sprinkle_dns/exceptions'
require 'sprinkle_dns/hosted_zone'
require 'sprinkle_dns/hosted_zone_domain'
require 'sprinkle_dns/hosted_zone_entry'
require 'sprinkle_dns/hosted_zone_alias'
require 'sprinkle_dns/core_ext/array_wrap'
require 'sprinkle_dns/core_ext/zonify'

module SprinkleDNS
  class Client
    attr_reader :wanted_hosted_zones

    def initialize(dns_provider)
      @dns_provider   = dns_provider
      @wanted_hosted_zones   = []
      @existing_zones = []
    end

    def entry(type, name, value, ttl = 3600, hosted_zone = nil)
      hosted_zone = find_or_init_hosted_zone(name, hosted_zone)
      name        = zonify!(name)

      if ['CNAME', 'MX'].include?(type)
        value = Array.wrap(value)
        value.map!{|v| zonify!(v)}
      end
      hosted_zone.add_or_update_hosted_zone_entry(HostedZoneEntry.new(type, name, Array.wrap(value), ttl, hosted_zone.name))
    end

    def alias(type, name, hosted_zone_id, dns_name, hosted_zone = nil)
      hosted_zone = find_or_init_hosted_zone(name, hosted_zone)
      name        = zonify!(name)

      hosted_zone.add_or_update_hosted_zone_entry(HostedZoneAlias.new(type, name, hosted_zone_id, dns_name, hosted_zone.name))
    end

    def sprinkle!
      puts @wanted_hosted_zones.map(&:name)

      @dns_provider.set_wanted_hosted_zones(@wanted_hosted_zones)

      @existing_hosted_zones = @dns_provider.get_hosted_zones(@wanted_hosted_zones)

      @dns_provider.sync!
    end

    private

    def find_or_init_hosted_zone(record_name, hosted_zone_name)
      hosted_zone_name ||= HostedZoneDomain::parse(record_name)
      hosted_zone_name   = zonify!(hosted_zone_name)

      wanted_hosted_zone = @wanted_hosted_zones.select{|zone| zone.name == hosted_zone_name}.first
      if wanted_hosted_zone.nil?
        wanted_hosted_zone = HostedZone.new(hosted_zone_name)
        @wanted_hosted_zones << wanted_hosted_zone
      end

      wanted_hosted_zone
    end
  end

end
