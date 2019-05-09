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

  end
end
