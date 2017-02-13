module SprinkleDNS
  class HostedZone
    attr_reader :hosted_zone_id, :name, :records_count
    attr_accessor :resource_record_sets

    def initialize(hosted_zone_id, name, records_count)
      @hosted_zone_id       = hosted_zone_id
      @name                 = name
      @records_count        = records_count
      @resource_record_sets = []
    end

    def add_or_update_hosted_zone_entry(wanted_entry)
      raise if wanted_entry.hosted_zone != self.name

      current_entry = @resource_record_sets.select{|hze| hze.type == wanted_entry.type && hze.name == wanted_entry.name}.first

      if current_entry
        current_entry.modify(wanted_entry.type, wanted_entry.name, wanted_entry.value, wanted_entry.ttl)
        current_entry.mark_referenced!
      else
        wanted_entry.mark_new!
        wanted_entry.mark_referenced!
        @resource_record_sets << wanted_entry
      end
    end

    def entries_to_create
      @resource_record_sets.select{|hze| hze.referenced?}.select{|hze| hze.new?}
    end

    def entries_to_update
      @resource_record_sets.select{|hze| hze.referenced?}.select{|hze| hze.changed? && !hze.new?}
    end

    def entries_to_delete
      @resource_record_sets.select{|hze| !hze.referenced?}
    end

    def modified?
      [entries_to_create, entries_to_update, entries_to_delete].map(&:size).inject(:+) > 0
    end

  end
end
