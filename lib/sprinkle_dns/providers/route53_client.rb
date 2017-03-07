require 'aws-sdk'

module SprinkleDNS
  Route53ChangeRequest = Struct.new(:hosted_zone, :change_info_id, :tries, :in_sync)

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

    def sync!
      change_requests = []

      hosted_zones.each do |hosted_zone|
        change_batch_options = []

        hosted_zone.entries_to_delete.each do |entry|
          # Figure out a way to pass options, and then delete
          puts "NOT DELETING #{entry}"
          if true == false
            change_batch_options << {
              action: 'DELETE',
              resource_record_set: {
                name: entry.name,
                type: entry.type,
                ttl: entry.ttl,
                resource_records: entry.value.map{|a| {value: a}},
              },
            }
          end
        end

        hosted_zone.entries_to_update.each do |entry|
          change_batch_options << {
            action: 'UPSERT',
            resource_record_set: {
              name: entry.name,
              type: entry.type,
              ttl: entry.ttl,
              resource_records: entry.value.map{|a| {value: a}},
            },
          }
        end

        hosted_zone.entries_to_create.each do |entry|
          change_batch_options << {
            action: 'CREATE',
            resource_record_set: {
              name: entry.name,
              type: entry.type,
              ttl: entry.ttl,
              resource_records: entry.value.map{|a| {value: a}},
            },
          }
        end

        if change_batch_options.any?
          change_request = @r53client.change_resource_record_sets({
            hosted_zone_id: hosted_zone.hosted_zone_id,
            change_batch: {
              changes: change_batch_options,
            }
          })
          change_requests << Route53ChangeRequest.new(hosted_zone, change_request.change_info.id, 1, false)
        else
          change_requests << Route53ChangeRequest.new(hosted_zone, nil, 1, true)
        end
      end

      redraw_change_request_state(change_requests, false)
      begin
        redraw_change_request_state(change_requests)

        change_requests.reject{|cr| cr.in_sync}.each do |change_request|
          resp = @r53client.get_change({id: change_request.change_info_id})
          change_request.in_sync = resp.change_info.status == 'INSYNC'
          change_request.tries  += 1
        end

        redraw_change_request_state(change_requests)
        sleep(3)
      end while(!change_requests.all?{|cr| cr.in_sync})
    end

    private

    def redraw_change_request_state(change_requests, clear_lines = true)
      lines = []

      change_requests.each do |change_request|
        dots   = '.' * change_request.tries
        sync   = change_request.in_sync ? '✔' : '✘'
        status = change_request.in_sync ? 'PROPAGATED' : 'PROPAGATING'
        lines << "#{sync} #{status} #{change_request.hosted_zone.name}#{dots}"
      end

      clear = clear_lines ? ("\r" + ("\e[A\e[K") * change_requests.size) : ''
      puts clear + lines.join("\n")
    end

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
        missing_hosted_zones = (@included_hosted_zones - hosted_zones.map(&:name)).join(',')
        raise "Whooops, the following hosted zones does not exist: #{missing_hosted_zones}"
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

        data.resource_record_sets.each do |rrs|
          next if ignored_record_types.include?(rrs.type) && rrs.name == hosted_zone.name
          existing_resource_record_sets << HostedZoneEntry.new(rrs.type, rrs.name, rrs.resource_records.map(&:value), rrs.ttl, hosted_zone.name)
        end
      end

      existing_resource_record_sets
    end
  end

end