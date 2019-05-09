module SprinkleDNS
  class HostedZoneAlias
    attr_accessor :type, :name, :hosted_zone, :target_hosted_zone_id, :target_dns_name
    attr_accessor :changed_type, :changed_name, :changed_target_hosted_zone_id, :changed_target_dns_name
    attr_accessor :referenced, :persisted
    attr_accessor :new_entry

    def initialize(type, name, target_hosted_zone_id, target_dns_name, hosted_zone)
      @type                  = type
      @name                  = zonify!(name)
      @target_hosted_zone_id = target_hosted_zone_id
      @target_dns_name       = target_dns_name
      @hosted_zone           = hosted_zone

      @new_entry = nil

      raise if [@type, @name, @target_hosted_zone_id, @target_dns_name, @hosted_zone].any?(&:nil?)

      @changed_type = false
      @changed_name = false
      @changed_target_hosted_zone_id = false
      @changed_target_dns_name = false
      @referenced = false
      @persisted = false
    end

    def mark_new!
      @changed_type, @changed_name, @changed_target_hosted_zone_id, @changed_target_dns_name = [true, true, true, true]
    end

    def new?
      [@changed_type, @changed_name, @changed_target_hosted_zone_id, @changed_target_dns_name].all?
    end

    def persisted!
      @persisted = true
    end

    def persisted?
      @persisted
    end

    def changed?
      [@changed_type, @changed_name, @changed_target_hosted_zone_id, @changed_target_dns_name].any?
    end

    def mark_referenced!
      @referenced = true
    end

    def referenced?
      @referenced
    end

    def new_value(new_entry)
      if new_entry.class == SprinkleDNS::HostedZoneAlias
        @changed_target_hosted_zone_id = true if @target_hosted_zone_id != new_entry.target_hosted_zone_id
        @changed_target_dns_name       = true if @target_dns_name       != new_entry.target_dns_name
      else
        @changed_target_hosted_zone_id = true
        @changed_target_dns_name       = true
      end

      # TODO test this
      if @changed_target_hosted_zone_id || @changed_target_dns_name
        @new_entry = new_entry
      end

      self.changed?
    end

    def to_s
      [
        "Alias",
        sprintf("%4s", type),
        sprintf("%30s", name),
        sprintf("%10s", target_hosted_zone_id),
        sprintf("%30s", target_dns_name),
        sprintf("%6s", hosted_zone),
      ].join(" ")
    end

    private

    def valid_record_types
      ['SOA','A','TXT','NS','CNAME','MX','NAPTR','PTR','SRV','SPF','AAAA']
    end

  end
end

