module EntryHelpers
  def entry(type, name, value, ttl = 3600, hosted_zone_name = nil)
    name = zonify!(name)

    if ['CNAME', 'MX'].include?(type)
      value = Array.wrap(value)
      value.map!{|v| zonify!(v)}
    end
    SprinkleDNS::HostedZoneEntry.new(type, name, Array.wrap(value), ttl, hosted_zone_name)
  end

  def alias(type, name, hosted_zone_id, dns_name, hosted_zone_name = nil)
    name = zonify!(name)

    SprinkleDNS::HostedZoneAlias.new(type, name, hosted_zone_id, dns_name, hosted_zone_name)
  end
end
