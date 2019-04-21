module SprinkleDNS
  class HostedZoneAlias
    attr_accessor :type, :name, :hosted_zone_id, :dns_name, :hosted_zone
    attr_accessor :changed_type, :changed_name, :changed_hosted_zone_id, :changed_dns_name
    attr_accessor :referenced

    def initialize(type, name, hosted_zone_id, dns_name, hosted_zone)
      @type           = type
      @name           = zonify!(name)
      @hosted_zone    = hosted_zone

      @hosted_zone_id         = hosted_zone_id
      @changed_hosted_zone_id = false
      @original_hosted_zone_id       = hosted_zone_id.clone

      @dns_name          = dns_name
      @changed_dns_name  = false
      @original_dns_name = dns_name.clone

      raise if [@type, @name, @hosted_zone_id, @dns_name, @hosted_zone].any?(&:nil?)
      @referenced    = false
    end

    def mark_new!
      @changed_type, @changed_name, @changed_hosted_zone_id, @changed_dns_name = [true, true, true, true]
    end

    def new?
      [@changed_type, @changed_name, @changed_hosted_zone_id, @changed_dns_name].all?
    end

    def changed?
      [@changed_type, @changed_name, @changed_hosted_zone_id, @changed_dns_name].any?
    end

    def mark_referenced!
      @referenced = true
    end

    def referenced?
      @referenced
    end

    def modify(hosted_zone_id, dns_name)
      @hosted_zone_id = hosted_zone_id
      @dns_name = dns_name

      @changed_hosted_zone_id = true if @original_hosted_zone_id != @hosted_zone_id
      @changed_dns_name = true if @original_dns_name != @dns_name

      self.changed?
    end


    def to_s
      [
        "Alias",
        sprintf("%4s", type),
        sprintf("%30s", name),
        sprintf("%10s", hosted_zone_id),
        sprintf("%30s", dns_name),
        sprintf("%6s", hosted_zone),
      ].join(" ")
    end

    private

    def valid_record_types
      ['SOA','A','TXT','NS','CNAME','MX','NAPTR','PTR','SRV','SPF','AAAA']
    end

  end
end

