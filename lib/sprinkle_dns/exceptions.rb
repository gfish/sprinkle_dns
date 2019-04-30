module SprinkleDNS
  class RecordNotAString < StandardError; end
  class RecordNotValid   < StandardError; end
  class TtlNotInteger    < StandardError; end
  class SettingNotBoolean < StandardError; end

  class MissingHostedZones < StandardError; end
  class DuplicatedHostedZones < StandardError; end
end
