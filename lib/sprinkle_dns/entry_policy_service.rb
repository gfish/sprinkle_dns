module SprinkleDNS
  class EntryPolicyService
    def initialize(hosted_zone, configuration)
      @hosted_zone = hosted_zone
      @configuration = configuration
    end

    def entries_to_create
      @hosted_zone.entries.select{|hze| hze.referenced? && hze.new?}
    end

    def entries_to_update
      @hosted_zone.entries.select{|hze| hze.referenced? && hze.changed? && !hze.new?}
    end

    def entries_not_touched
      not_touched = @hosted_zone.entries.select{|hze| hze.referenced? && !hze.changed? && !hze.new?}

      if @configuration.delete?
        not_touched
      else
        (not_touched + @hosted_zone.entries.select{|hze| !hze.referenced?}).flatten
      end
    end

    def entries_to_delete
      if @configuration.delete?
        @hosted_zone.entries.select{|hze| !hze.referenced?}
      else
        []
      end
    end

    def entries_to_change
      [entries_to_create, entries_to_update, entries_to_delete].map(&:size).inject(:+)
    end

    def entries_to_change?
      entries_to_change > 0
    end

    def compile
      generate_change_batch
    end

    private

    def generate_change_batch
      change_batch_options = []

      entries_to_delete.each do |entry|
        change_batch_options << {
          action: 'DELETE',
          resource_record_set: entry_to_rrs(entry),
        }
      end

      entries_to_update.each do |entry|
        change_batch_options << {
          action: 'UPSERT',
          resource_record_set: entry_to_rrs(entry.new_entry),
        }
      end

      entries_to_create.each do |entry|
        change_batch_options << {
          action: 'CREATE',
          resource_record_set: entry_to_rrs(entry)
        }
      end

      change_batch_options
    end

    private

    def entry_to_rrs(entry)
      case entry
      when HostedZoneEntry
        {
          name: entry.name,
          type: entry.type,
          ttl: entry.ttl,
          resource_records: entry.value.map{|a| {value: a}},
        }
      when HostedZoneAlias
        {
          name: entry.name,
          type: entry.type,
          alias_target: {
            hosted_zone_id: entry.target_hosted_zone_id,
            dns_name: entry.target_dns_name,
            evaluate_target_health: false,
          },
        }
      else raise "Unknown entry"
      end
    end
  end
end
