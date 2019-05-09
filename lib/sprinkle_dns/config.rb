module SprinkleDNS
  class Config
    def initialize(dry_run: true, diff: true, force: false, delete: false, interactive_progress: true, create_hosted_zones: false, show_untouched: false)
      @dry_run = dry_run
      @diff = diff
      @force = force
      @delete = delete
      @interactive_progress = interactive_progress
      @create_hosted_zones = create_hosted_zones
      @show_untouched = show_untouched

      raise SettingNotBoolean.new('dry_run is not a boolean') unless [true, false].include?(dry_run)
      raise SettingNotBoolean.new('diff is not a boolean') unless [true, false].include?(diff)
      raise SettingNotBoolean.new('force is not a boolean') unless [true, false].include?(force)
      raise SettingNotBoolean.new('delete is not a boolean') unless [true, false].include?(delete)
      raise SettingNotBoolean.new('interactive_progress is not a boolean') unless [true, false].include?(interactive_progress)
      raise SettingNotBoolean.new('create_hosted_zones is not a boolean') unless [true, false].include?(create_hosted_zones)
      raise SettingNotBoolean.new('show_untouched is not a boolean') unless [true, false].include?(show_untouched)
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

    def create_hosted_zones?
      @create_hosted_zones
    end

    def show_untouched?
      @show_untouched
    end
  end
end
