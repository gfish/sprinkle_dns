module SprinkleDNS
  class HostedZone
    attr_reader :name
    attr_accessor :resource_record_sets

    def initialize(name)
      @name                 = name
      @resource_record_sets = []
    end

    def add_or_update_hosted_zone_entry(wanted_entry)
      raise if wanted_entry.hosted_zone != self.name

      existing_entry = @resource_record_sets.find{|hze| hze.type == wanted_entry.type && hze.name == wanted_entry.name}

      if existing_entry
        if existing_entry.persisted?
          existing_entry.mark_referenced!
          existing_entry.new_value(wanted_entry)
        else
          wanted_entry.mark_referenced!
          @resource_record_sets[@resource_record_sets.index(existing_entry)] = wanted_entry
        end
      else
        wanted_entry.mark_new!
        wanted_entry.mark_referenced!
        @resource_record_sets << wanted_entry
      end
    end

    def entries
      @resource_record_sets
    end

    def entries_to_create
      @resource_record_sets.select{|hze| hze.referenced? && hze.new?}
    end

    def entries_to_update
      @resource_record_sets.select{|hze| hze.referenced? && hze.changed? && !hze.new?}
    end

    def entries_to_delete
      @resource_record_sets.select{|hze| !hze.referenced?}
    end

    def entries_not_touched
      @resource_record_sets.select{|hze| hze.referenced? && !hze.new? && !hze.changed?}
    end

    def entries_to_change?
      [entries_to_create, entries_to_update, entries_to_delete].map(&:size).inject(:+) > 0
    end

    def compile_change_batch
      change_batch_options = []

      entries_to_delete.each do |entry|
        # Figure out a way to pass options, and then delete
        puts "NOT DELETING #{entry}"
        if true == false
          change_batch_options << {
            action: 'DELETE',
            resource_record_set: entry_to_rrs(entry),
          }
        end
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
