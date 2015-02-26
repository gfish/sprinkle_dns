module SprinkleDNS
  class ZoneEntry < Struct.new(:type, :name, :value, :ttl)
    def ==(other)
      type == other.type &&
      name == other.name
    end

    def to_s
      [
        sprintf("%4s", type),
        sprintf("%30s", name),
        sprintf("%50s", value.join(", ")),
        sprintf("%6s", ttl)
      ].join(" ")
    end
  end
end
