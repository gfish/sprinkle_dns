require 'sprinkle_dns/hosted_zone_domain'
require 'sprinkle_dns/hosted_zone_entry'
require 'sprinkle_dns/core_ext/array_wrap'
require 'sprinkle_dns/core_ext/zonify'

module SprinkleDNS
  class Client
    def initialize(r53client)
      @r53client    = r53client
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
      @wanted_zones[hosted_zone] << HostedZoneEntry.new(type, zonify!(name), Array.wrap(value), ttl.to_s, zonify!(hosted_zone))
    end

    def sprinkle!
      @wanted_zones.each do |hosted_zone_name, hosted_zone_entries|
        @r53client.add_hosted_zone(hosted_zone_name)
      end
      existing_zones = @r53client.get_hosted_zones!

      _hosted_zones = {}
      existing_zones.each do |hosted_zone|
        _hosted_zones[hosted_zone.name] = hosted_zone.resource_record_sets
      end
      @wanted_zones.each do |hosted_zone_name, hosted_zone_entries|
        _hosted_zones[hosted_zone_name] ||= []

        hosted_zone_entries.each do |wanted_entry|
          hze = _hosted_zones[hosted_zone_name].select{|hze| hze.type == wanted_entry.type && hze.name == wanted_entry.name}.first

          if !hze.nil?
            hze.modify(
              wanted_entry.type,
              wanted_entry.name,
              wanted_entry.value,
              wanted_entry.ttl,
            )
            hze.mark_referenced!
          else
            wanted_entry.mark_new!
            wanted_entry.mark_referenced!
            _hosted_zones[hosted_zone_name] << wanted_entry
          end
        end
      end

      _hosted_zones.each do |hosted_zone, hosted_zone_entries|
        to_create = hosted_zone_entries.select{|hze| hze.referenced?}.select{|hze| hze.new?}
        to_update = hosted_zone_entries.select{|hze| hze.referenced?}.select{|hze| hze.changed? && !hze.new?}
        to_delete = hosted_zone_entries.select{|hze| !hze.referenced?}

        raise if hosted_zone_entries.size != [to_create, to_update, to_delete].map(&:size).sum
      end

    end
  end

end
