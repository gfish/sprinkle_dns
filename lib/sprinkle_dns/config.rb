module SprinkleDNS
  class Config
    def initialize(dry_run: false, diff: true, force: true, delete: false)
      @dry_run = dry_run
      @diff = diff
      @force = force
      @delete = delete

      raise SettingNotBoolean.new('dry_run is not a boolean') unless [true, false].include?(dry_run)
      raise SettingNotBoolean.new('diff is not a boolean') unless [true, false].include?(diff)
      raise SettingNotBoolean.new('force is not a boolean') unless [true, false].include?(force)
      raise SettingNotBoolean.new('delete is not a boolean') unless [true, false].include?(delete)
    end

    def dry_run?
      @dry_run
    end

    def diff?
      @diff
    end

    def force?
      @force
    end

    def delete?
      @delete
    end
  end
end
