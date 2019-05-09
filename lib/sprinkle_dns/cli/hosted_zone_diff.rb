module SprinkleDNS::CLI
  class HostedZoneDiff
    HostedZone = Struct.new(:action, :name)
    Entry = Struct.new(:action, :type, :type_highlight, :name, :name_highlight, :value1, :value1_highlight, :value2, :value2_highlight, :hosted_zone)

    def diff(existing_hosted_zones, missing_hosted_zones, configuration)
      entries = []

      hosted_zones = if configuration.create_hosted_zones?
        (existing_hosted_zones + missing_hosted_zones)
      else
        existing_hosted_zones
      end

      hosted_zones.each do |hosted_zone|
        policy_service = SprinkleDNS::EntryPolicyService.new(hosted_zone, configuration)

        to_create = policy_service.entries_to_create
        to_update = policy_service.entries_to_update
        to_delete = policy_service.entries_to_delete

        if missing_hosted_zones.include?(hosted_zone)
          entries << hosted_zone_to_struct('+', hosted_zone)
        end

        hosted_zone.entries.each do |entry|
          if to_create.include?(entry)
            entries << entry_to_struct('+', entry, hosted_zone)
          elsif to_update.include?(entry)
            old_entry = entry
            new_entry = entry.new_entry

            entries << entry_to_struct('u-', old_entry, hosted_zone)
            entries << entry_to_struct('u+', new_entry, hosted_zone, old_entry)
          elsif to_delete.include?(entry)
            entries << entry_to_struct('-', entry, hosted_zone)
          else
            if configuration.show_untouched?
              entries << entry_to_struct(nil, entry, hosted_zone)
            end
          end
        end
      end

      coloured_entries = []

      entries.each do |e|
        colour_mod = case e.action
        when '+'
          ->(text) { "#{fg(*green)}#{text}#{color_reset}" }
        when '-'
          ->(text) { "#{fg(*red)}#{text}#{color_reset}" }
        when nil
          ->(text) { "#{text}" }
        end

        colour_mod_highlight = case e.action
        when '+'
          ->(text) { "#{fg(*black)}#{bg(*green)}#{text}#{color_reset}" }
        when '-'
          ->(text) { "#{fg(*black)}#{bg(*red)}#{text}#{color_reset}" }
        when nil
          ->(text) { "#{text}" }
        end

        case e
        when HostedZone
          information = [colour_mod.call(e.action), colour_mod_highlight.call(bold(e.name))]
        when Entry
          information = [colour_mod.call(e.action)]

          information << if e.type_highlight
            colour_mod_highlight.call(e.type)
          else
            colour_mod.call(e.type)
          end

          information << if e.name_highlight
            colour_mod_highlight.call(e.name)
          else
            colour_mod.call(e.name)
          end

          information << if e.value1_highlight
            colour_mod_highlight.call(e.value1)
          else
            colour_mod.call(e.value1)
          end

          information << if e.value2_highlight
            colour_mod_highlight.call(e.value2)
          else
            colour_mod.call(e.value2)
          end
        end

        coloured_entries << information.compact.delete_if(&:empty?)
      end

      coloured_entries
    end

    private

    def hex_to_rgb(hex)
      hex_split = hex.match(/#(..)(..)(..)/)
      [hex_split[1], hex_split[2], hex_split[3]].map(&:hex)
    end

    def red
     hex_to_rgb('#ff6e67')
    end

    def green
     hex_to_rgb('#5bf68c')
    end

    def black
     hex_to_rgb('#000000')
    end

    def fg(r, g, b)
      "\x1b[38;2;#{r};#{g};#{b}m"
    end

    def bg(r, g, b)
      "\x1b[48;2;#{r};#{g};#{b}m"
    end

    def color_reset
      "\x1b[0m"
    end

    def bold(text)
      "\033[1m#{text}\033[0m"
    end

    def hosted_zone_to_struct(action, hosted_zone)
      HostedZone.new(action, hosted_zone.name)
    end

    def entry_to_struct(action, entry, hosted_zone, parent_entry = nil)
      type_highlight, name_highlight, value1_highlight, value2_highlight = if !parent_entry && ['+', '-'].include?(action)
        [true, true, true, true]
      else
        [false, false, nil, nil]
      end

      action = case action
      when 'u-'
        '-'
      when 'u+'
        '+'
      else
        action
      end

      value1_highlight ||= if parent_entry
        case parent_entry
        when SprinkleDNS::HostedZoneEntry
          parent_entry.changed_value
        when SprinkleDNS::HostedZoneAlias
          parent_entry.changed_target_hosted_zone_id
        end
      else
        case entry
        when SprinkleDNS::HostedZoneEntry
          entry.changed_value
        when SprinkleDNS::HostedZoneAlias
          entry.changed_target_hosted_zone_id
        end
      end

      value2_highlight ||= if parent_entry
        case parent_entry
        when SprinkleDNS::HostedZoneEntry
          parent_entry.changed_ttl
        when SprinkleDNS::HostedZoneAlias
          parent_entry.changed_target_dns_name
        end
      else
        case entry
        when SprinkleDNS::HostedZoneEntry
          entry.changed_ttl
        when SprinkleDNS::HostedZoneAlias
          entry.changed_target_dns_name
        end
      end

      case entry
      when SprinkleDNS::HostedZoneEntry
        Entry.new(action,
                  entry.type, type_highlight,
                  entry.name, name_highlight,
                  entry.value, value1_highlight,
                  entry.ttl, value2_highlight,
                  hosted_zone.name)
      when SprinkleDNS::HostedZoneAlias
        Entry.new(action,
                  entry.type, type_highlight,
                  entry.name, name_highlight,
                  entry.target_hosted_zone_id, value1_highlight,
                  entry.target_dns_name, value2_highlight,
                  hosted_zone.name)
      end
    end
  end
end
