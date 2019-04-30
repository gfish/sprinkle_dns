module SprinkleDNS
  class Config
    def initialize(dry_run: false, diff: true, force: true, delete: false, interactive_progress: true)
      @dry_run = dry_run
      @diff = diff
      @force = force
      @delete = delete
      @interactive_progress = interactive_progress

      raise SettingNotBoolean.new('dry_run is not a boolean') unless [true, false].include?(dry_run)
      raise SettingNotBoolean.new('diff is not a boolean') unless [true, false].include?(diff)
      raise SettingNotBoolean.new('force is not a boolean') unless [true, false].include?(force)
      raise SettingNotBoolean.new('delete is not a boolean') unless [true, false].include?(delete)
      raise SettingNotBoolean.new('interactive_progress is not a boolean') unless [true, false].include?(interactive_progress)
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

    def interactive_progress?
      @interactive_progress
    end
  end
end
