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
      @dns_provider = dns_provider
      @wanted_hosted_zones = []
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

    def sprinkle
      existing_hosted_zones = @dns_provider.fetch_hosted_zones(filter: @wanted_hosted_zones.map(&:name))

      # Make sure we have the same amount of zones
      unless existing_hosted_zones.map(&:name) - @wanted_hosted_zones.map(&:name) == []
        error_message = []
        error_message << "We found #{existing_hosted_zones.size} existing zones, but #{@wanted_hosted_zones} was described, exiting!"
        error_message << ""

        error_message << "Existing:"
        existing_hosted_zones.map(&:name).sort.each do |ehz|
          error_message << "- #{ehz}"
        end

        error_message << "Described:"
        @wanted_hosted_zones.map(&:name).sort.each do |whz|
          error_message << "- #{whz}"
        end

        raise error_message.join("\n")
      end

      existing_hosted_zones.each do |existing_hosted_zone|
        wanted_hosted_zone = @wanted_hosted_zones.select{|whz| whz.name == existing_hosted_zone.name}.first

        wanted_hosted_zone.resource_record_sets.each do |entry|
          existing_hosted_zone.add_or_update_hosted_zone_entry(entry)
        end
      end

      [@wanted_hosted_zones, existing_hosted_zones]
    end

    def sprinkle!
      wanted_hosted_zones, existing_hosted_zones = sprinkle

      puts existing_hosted_zones.map(&:name)
      puts wanted_hosted_zones.map(&:name)
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
