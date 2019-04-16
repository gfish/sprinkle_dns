require 'sprinkle_dns/exceptions'
require 'sprinkle_dns/hosted_zone'
require 'sprinkle_dns/hosted_zone_domain'
require 'sprinkle_dns/hosted_zone_entry'
require 'sprinkle_dns/alias_entry'
require 'sprinkle_dns/core_ext/array_wrap'
require 'sprinkle_dns/core_ext/zonify'

module SprinkleDNS
  class Client
    attr_reader :wanted_zones

    def initialize(dns_provider)
      @dns_provider = dns_provider
      @wanted_zones = {}
    end

    def entry(type, name, value, ttl = 3600, hosted_zone = nil)
      hosted_zone                ||= HostedZoneDomain::parse(name)
      hosted_zone                  = zonify!(hosted_zone)
      @wanted_zones[hosted_zone] ||= []

      if ['CNAME', 'MX'].include?(type)
        value = Array.wrap(value)
        value.map!{|v| zonify!(v)}
      end
      @wanted_zones[hosted_zone] << HostedZoneEntry.new(type, zonify!(name), Array.wrap(value), ttl, zonify!(hosted_zone))
    end

    def alias(type, name, hosted_zone_id, dns_name, hosted_zone = nil)
      hosted_zone                ||= HostedZoneDomain::parse(name)
      hosted_zone                  = zonify!(hosted_zone)
      @wanted_zones[hosted_zone] ||= []

      @wanted_zones[hosted_zone] << AliasEntry.new(type, zonify!(name), hosted_zone_id, dns_name, zonify!(hosted_zone))
    end

    def sprinkle!
      @dns_provider.set_hosted_zones(@wanted_zones.keys)

      @wanted_zones.each do |hosted_zone_name, hosted_zone_entries|
        hosted_zone_entries.each do |wanted_entry|
          @dns_provider.add_or_update_hosted_zone_entry(wanted_entry)
        end
      end

      @dns_provider.sync!
    end
  end

end
