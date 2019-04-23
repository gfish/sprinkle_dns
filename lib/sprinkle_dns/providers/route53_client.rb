require 'aws-sdk-route53'

module SprinkleDNS
  Route53ChangeRequest = Struct.new(:hosted_zone, :change_info_id, :tries, :in_sync)

  class Route53Client
    attr_reader :hosted_zones

    def initialize(aws_access_key_id, aws_secret_access_key)
      @api_client = Aws::Route53::Client.new(
        access_key_id: aws_access_key_id,
        secret_access_key: aws_secret_access_key,
        region: 'us-east-1',
      )
    end

    def fetch_hosted_zones(filter: [])
      hosted_zones = []
      more_pages   = true
      next_marker  = nil

      if filter.empty?
        return []
      end

      while(more_pages)
        begin
          data = @api_client.list_hosted_zones({:max_items => nil, :marker => next_marker})
        rescue Aws::Route53::Errors::AccessDenied
          # TODO extract this to custom exceptions
          raise
        end

        more_pages  = data.is_truncated
        next_marker = data.next_marker

        data.hosted_zones.each do |hosted_zone_data|
          if filter.include?(hosted_zone_data.name)

            if hosted_zones.map(&:name).include?(hosted_zone_data.name)
              raise DuplicatedHostedZones, "Whooops, seems like you have the same hosted zone duplicated on your Route53 account!\nIt's the following: #{hz.name}"
            end

            hosted_zone = HostedZone.new(hosted_zone_data.name)
            hosted_zone.resource_record_sets = get_resource_record_set!(hosted_zone, hosted_zone_data.id)

            hosted_zones << hosted_zone
          end
        end
      end

      if hosted_zones.size != filter.size
        missing_hosted_zones = (filter - hosted_zones.map(&:name)).join(',')
        raise MissingHostedZones, "Whooops, the following hosted zones does not exist: #{missing_hosted_zones}"
      end

      hosted_zones
    end

    private

    def ignored_record_types
      ['NS','SOA']
    end

    def get_resource_record_set!(hosted_zone, hosted_zone_id)
      existing_resource_record_sets = []
      more_pages                    = true
      next_record_name              = nil
      next_record_type              = nil
      next_record_identifier        = nil

      while(more_pages)
        data = @api_client.list_resource_record_sets(
          hosted_zone_id: hosted_zone_id,
          max_items: nil,
          start_record_name: next_record_name,
          start_record_type: next_record_type,
          start_record_identifier: next_record_identifier,
        )
        more_pages = data.is_truncated

        next_record_name       = data.next_record_name
        next_record_type       = data.next_record_type
        next_record_identifier = data.next_record_identifier

        data.resource_record_sets.each do |rrs|
          rrs_name = rrs.name
          rrs_name = rrs_name.gsub('\\052', '*')
          rrs_name = rrs_name.gsub('\\100', '@')

          next if ignored_record_types.include?(rrs.type) && rrs_name == hosted_zone.name

          entry = if rrs.alias_target
            HostedZoneAlias.new(rrs.type, rrs_name, rrs.alias_target.hosted_zone_id, rrs.alias_target.dns_name, hosted_zone.name)
          else
            HostedZoneEntry.new(rrs.type, rrs_name, rrs.resource_records.map(&:value), rrs.ttl, hosted_zone.name)
          end

          existing_resource_record_sets << entry
          entry.persisted!
        end
      end

      existing_resource_record_sets
    end
  end
end
