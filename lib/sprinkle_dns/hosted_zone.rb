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
  end
end
