require 'aws-sdk'

module SprinkleDNS

  class Route53Client
    attr_reader :hosted_zones

    def initialize(aws_access_key_id, aws_secret_access_key)
      @r53client = Aws::Route53::Client.new(
        access_key_id: aws_access_key_id,
        secret_access_key: aws_secret_access_key,
        region: 'us-east-1',
      )

      @included_hosted_zones = []
      @hosted_zones          = []
    end

    def set_hosted_zones(hosted_zone_names)
      @included_hosted_zones = Array.wrap(hosted_zone_names).map{|hzn| zonify!(hzn)}
      @hosted_zones          = []

      get_hosted_zones!
    end

    def add_or_update_hosted_zone_entry(hosted_zone_entry)
      hosted_zone = @hosted_zones.select{|hz| hz.name == hosted_zone_entry.hosted_zone}.first
      hosted_zone.add_or_update_hosted_zone_entry(hosted_zone_entry)
    end

    private

    def get_hosted_zones!
      hosted_zones = []
      more_pages   = true
      next_marker  = nil

      while(more_pages)
        data = @r53client.list_hosted_zones({:max_items => nil, :marker => next_marker})

        more_pages  = data.is_truncated
        next_marker = data.next_marker

        data.hosted_zones.each do |hz|
          if @included_hosted_zones.include?(hz.name)
            hosted_zone = HostedZone.new(hz.id, hz.name, hz.resource_record_set_count)
            hosted_zone.resource_record_sets = get_resource_record_set!(hosted_zone)

            hosted_zones << hosted_zone
          end
        end
      end

      if @included_hosted_zones.size != hosted_zones.size
        missing_hosted_zones = (@included_hosted_zones - hosted_zones).join(',')
        raise "Whooops, missing hosted zones: #{missing_hosted_zones}"
      end

      @hosted_zones = hosted_zones
    end

    def ignored_record_types
      ['NS','SOA']
    end

    def get_resource_record_set!(hosted_zone)
      more_pages                    = true
      next_record_name              = nil
      next_record_type              = nil
      next_record_identifier        = nil
      existing_resource_record_sets = []

      while(more_pages)
        data = @r53client.list_resource_record_sets(
          hosted_zone_id: hosted_zone.hosted_zone_id,
          max_items: nil,
          start_record_name: next_record_name,
          start_record_type: next_record_type,
          start_record_identifier: next_record_identifier,
        )
        more_pages = data.is_truncated

        next_record_name       = data.next_record_name
        next_record_type       = data.next_record_type
        next_record_identifier = data.next_record_identifier
        print '.'

        data.resource_record_sets.each do |rrs|
          next if ignored_record_types.include?(rrs.type)
          existing_resource_record_sets << HostedZoneEntry.new(rrs.type, rrs.name, rrs.resource_records.map(&:value), rrs.ttl, hosted_zone.name)
        end
      end
      puts
      existing_resource_record_sets
    end
  end

end
