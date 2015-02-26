module SprinkleDNS
  class ZoneEntry < Struct.new(:type, :name, :value, :ttl)
    def ==(other)
      type == other.type &&
      name == other.name
    end
  end
end
