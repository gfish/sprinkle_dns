module SprinkleDNS
  class HostedZoneEntry
    attr_accessor :type, :name, :value, :ttl, :hosted_zone
    attr_accessor :changed_type, :changed_name, :changed_value, :changed_ttl
    attr_accessor :referenced

    def initialize(type, name, value, ttl, hosted_zone)
      @type           = type
      @name           = zonify!(name)
      @value          = Array.wrap(value)
      @original_value = @value
      @ttl            = ttl.to_i
      @original_ttl   = ttl
      @hosted_zone    = hosted_zone

      raise if [@type, @name, @value, @ttl, @hosted_zone].any?(&:nil?)

      @changed_type  = false
      @changed_name  = false
      @changed_value = false
      @changed_ttl   = false

      @referenced    = false

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

    def changed?
      [@changed_type, @changed_name, @changed_value, @changed_ttl].any?
    end

    def mark_referenced!
      @referenced = true
    end

    def referenced?
      @referenced
    end

    def modify(value, ttl)
      @value = value
      @ttl   = ttl

      @changed_value = true if @original_value != @value
      @changed_ttl   = true if @original_ttl   != @ttl

      puts "OLD=#{@original_value}, NEW=#{@value}" if @changed_value
      puts "OLD=#{@original_ttl}, NEW=#{@ttl}"     if @changed_ttl

      self.changed?
    end

    def ==(other)
      type  == other.type &&
      name  == other.name &&
      value == other.value &&
      ttl   == other.ttl
    end

    def to_s
      [
        sprintf("%4s", type),
        sprintf("%30s", name),
        sprintf("%50s", value.join(", ")),
        sprintf("%6s", ttl),
        sprintf("%6s", hosted_zone),
      ].join(" ")
    end

  end
end
