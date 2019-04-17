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

    def sync!
      change_requests = []

      hosted_zones.each do |hosted_zone|
        change_batch_options = hosted_zone.compile_change_batch

        if change_batch_options.any?
          begin
            change_request = @api_client.change_resource_record_sets({
              hosted_zone_id: hosted_zone.hosted_zone_id,
              change_batch: {
                changes: change_batch_options,
              }
            })
          rescue Aws::Route53::Errors::AccessDenied
            # TODO extract this to custom exceptions
            raise
          end
          change_requests << Route53ChangeRequest.new(hosted_zone, change_request.change_info.id, 1, false)
        else
          change_requests << Route53ChangeRequest.new(hosted_zone, nil, 1, true)
        end
      end

      begin
        change_requests.reject{|cr| cr.in_sync}.each do |change_request|
          resp = @api_client.get_change({id: change_request.change_info_id})
          change_request.in_sync = resp.change_info.status == 'INSYNC'
          change_request.tries  += 1
        end
        sleep(3)
      end while(!change_requests.all?{|cr| cr.in_sync})
    end

    private

    def get_hosted_zones!
      hosted_zones = []
      more_pages   = true
      next_marker  = nil

      while(more_pages)
        begin
          data = @api_client.list_hosted_zones({:max_items => nil, :marker => next_marker})
        rescue Aws::Route53::Errors::AccessDenied
          # TODO extract this to custom exceptions
          raise
        end

        more_pages  = data.is_truncated
        next_marker = data.next_marker

        data.hosted_zones.each do |hz|
          if @included_hosted_zones.include?(hz.name)
            if hosted_zones.map(&:name).include?(hz.name)
              raise DuplicatedHostedZones, "Whooops, seems like you have the same hosted zone duplicated on your Route53 account!\nIt's the following: #{hz.name}"
            end

            hosted_zone = HostedZone.new(hz.id, hz.name)
            hosted_zone.resource_record_sets = get_resource_record_set!(hosted_zone)

            hosted_zones << hosted_zone
          end
        end
      end

      if @included_hosted_zones.size != hosted_zones.size
        missing_hosted_zones = (@included_hosted_zones - hosted_zones.map(&:name)).join(',')
        raise MissingHostedZones, "Whooops, the following hosted zones does not exist: #{missing_hosted_zones}"
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
        data = @api_client.list_resource_record_sets(
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

        data.resource_record_sets.each do |rrs|
          # TODO add spec for this
          rrs_name = rrs.name
          rrs_name = rrs_name.gsub('\\052', '*')
          rrs_name = rrs_name.gsub('\\100', '@')

          next if ignored_record_types.include?(rrs.type) && rrs_name == hosted_zone.name
          if rrs.alias_target
            existing_resource_record_sets << HostedZoneAlias.new(rrs.type, rrs_name, rrs.alias_target.hosted_zone_id, rrs.alias_target.dns_name, hosted_zone.name)
          else
            existing_resource_record_sets << HostedZoneEntry.new(rrs.type, rrs_name, rrs.resource_records.map(&:value), rrs.ttl, hosted_zone.name)
          end
        end
      end

      existing_resource_record_sets
    end
  end
end
