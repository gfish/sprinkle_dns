require 'fog'
require 'sprinkle_dns/zone_entry'

module SprinkleDNS

  class AwsDNS
    attr_reader :hosted_zones

    def initialize(aws_access_key_id, aws_secret_access_key)
      @dns = Fog::DNS.new({
        provider:              'AWS',
        aws_access_key_id:     aws_access_key_id,
        aws_secret_access_key: aws_secret_access_key,
      })

      @hosted_zones = {}
      @zone_ids = {}

      @dns.zones.each do |zone|
        @hosted_zones[zone.domain] = []
        add_zone_id(zone.domain, zone.id)

        zone.records.each do |record|
          next if ignored_record_types.include?(record.type)
          @hosted_zones[zone.domain] << ZoneEntry.new(record.type, record.name, record.value, record.ttl)
        end
      end
    end

    def id_for_zone(domain)
      @zone_ids[domain]
    end

   private

    def ignored_record_types
      ['NS','SOA']
    end

    def add_zone_id(domain, id)
      raise "Not supported" if @zone_ids[domain]
      @zone_ids[domain] = id
    end
  end

end
