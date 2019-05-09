module SprinkleDNS
  class HostedZoneEntry
    attr_accessor :type, :name, :value, :ttl, :hosted_zone
    attr_accessor :changed_type, :changed_name, :changed_value, :changed_ttl
    attr_accessor :referenced, :persisted
    attr_accessor :new_entry

    def initialize(type, name, value, ttl, hosted_zone)
      @type           = type
      @name           = zonify!(name)
      @value          = Array.wrap(value)
      @ttl            = ttl
      @hosted_zone    = hosted_zone

      @new_entry      = nil

      raise if [@type, @name, @value, @ttl, @hosted_zone].any?(&:nil?)
      raise SprinkleDNS::RecordNotAString.new('Record-type should be a string') unless @type.is_a?(String)
      raise SprinkleDNS::RecordNotValid.new("Record #{@type} is not supported") if !valid_record_types.include?(@type)
      raise SprinkleDNS::TtlNotInteger.new('TTL should be an integer') unless @ttl.is_a?(Integer)

      @changed_type  = false
      @changed_name  = false
      @changed_value = false
      @changed_ttl   = false
      @referenced    = false
      @persisted     = false

      if ['CNAME', 'MX'].include?(type)
        @value = @value.map!{|v| zonify!(v)}
      end
    end

    def mark_new!
      @changed_type, @changed_name, @changed_value, @changed_ttl = [true, true, true, true]
    end

    def new?
      [@changed_type, @changed_name, @changed_value, @changed_ttl].all?
    end

    def persisted!
      @persisted = true
    end

    def persisted?
      @persisted
    end

    def changed?
      [@changed_type, @changed_name, @changed_value, @changed_ttl].any?
    end

    def mark_referenced!
      @referenced = true
    end

    def referenced?
      @referenced
    end

    def new_value(new_entry)
      if new_entry.class == SprinkleDNS::HostedZoneEntry
        @changed_value = true if @value != new_entry.value
        @changed_ttl   = true if @ttl   != new_entry.ttl
      else
        @changed_value = true
        @changed_ttl   = true
      end

      # TODO test this
      if @changed_value || @changed_ttl
        @new_entry = new_entry
      end

      self.changed?
    end

    def to_s
      [
        "Entry",
        sprintf("%4s", type),
        sprintf("%30s", name),
        sprintf("%50s", value.join(", ")),
        sprintf("%6s", ttl),
        sprintf("%6s", hosted_zone),
      ].join(" ")
    end

    private

    def valid_record_types
      ['SOA','A','TXT','NS','CNAME','MX','NAPTR','PTR','SRV','SPF','AAAA']
    end

  end
end
