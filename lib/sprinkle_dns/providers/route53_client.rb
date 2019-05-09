require 'aws-sdk-route53'
require 'sprinkle_dns/version'

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
      @hosted_zone_to_api_mapping = {}
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
            @hosted_zone_to_api_mapping[hosted_zone.name] = hosted_zone_data.id

            hosted_zones << hosted_zone
          end
        end
      end

      hosted_zones
    end

    def create_hosted_zones(hosted_zones)
      change_requests = []

      hosted_zones.each do |hosted_zone|
        change_request = @api_client.create_hosted_zone({
          name: hosted_zone.name,
          caller_reference: "#{hosted_zone.name}.#{Time.now.to_i}",
          hosted_zone_config: {
            comment: "Created by SprinkleDNS #{SprinkleDNS::VERSION}",
          },
        })
        @hosted_zone_to_api_mapping[hosted_zone.name] = change_request.hosted_zone.id
        change_requests << Route53ChangeRequest.new(hosted_zone, change_request.change_info.id, 0, false)
      end

      change_requests
    end

    def change_hosted_zones(hosted_zones, configuration)
      change_requests = []

      hosted_zones.each do |hosted_zone|
        changes = EntryPolicyService.new(hosted_zone, configuration).compile

        if changes.any?
          change_request = @api_client.change_resource_record_sets({
            hosted_zone_id: @hosted_zone_to_api_mapping[hosted_zone.name],
            change_batch: {
              changes: changes,
            }
          })

          change_requests << Route53ChangeRequest.new(hosted_zone, change_request.change_info.id, 0, false)
        end
      end

      change_requests
    end

    def check_change_requests(change_requests)
      change_requests.reject{|cr| cr.in_sync}.each do |change_request|
        resp = @api_client.get_change({id: change_request.change_info_id})
        change_request.in_sync = resp.change_info.status == 'INSYNC'
        change_request.tries += 1
      end

      change_requests
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
          entry.persisted! # TODO test if all entries from are persisted = true
        end
      end

      existing_resource_record_sets
    end
  end
end
