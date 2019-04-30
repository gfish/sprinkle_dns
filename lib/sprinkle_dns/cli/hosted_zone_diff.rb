module SprinkleDNS::CLI
  class HostedZoneDiff
    Entry = Struct.new(:action, :type, :name, :value1, :value1_highlight, :value2, :value2_highlight, :hosted_zone)

    def diff(hosted_zones)
      entries = []

      hosted_zones.each do |hosted_zone|
        to_create = hosted_zone.entries_to_create
        to_update = hosted_zone.entries_to_update
        to_delete = hosted_zone.entries_to_delete

        hosted_zone.entries.each do |entry|
          if to_create.include?(entry)
            entries << entry_to_struct('+', entry, hosted_zone)
          elsif to_update.include?(entry)
            old_entry = entry
            new_entry = entry.new_entry

            entries << entry_to_struct('-', old_entry, hosted_zone)
            entries << entry_to_struct('+', new_entry, hosted_zone, old_entry)
          elsif to_delete.include?(entry)
            entries << entry_to_struct('-', entry, hosted_zone)
          else
            entries << entry_to_struct(nil, entry, hosted_zone)
          end
        end
      end

      coloured_entries = []

      entries.each do |e|
        colour_mod = case e.action
        when '+'
          ->(text) { "#{fg(*green)}#{text}#{reset}" }
        when '-'
          ->(text) { "#{fg(*red)}#{text}#{reset}" }
        when nil
          ->(text) { text }
        end

        colour_mod_highlight = case e.action
        when '+'
          ->(text) { "#{fg(*black)}#{bg(*green)}#{text}#{reset}" }
        when '-'
          ->(text) { "#{fg(*black)}#{bg(*red)}#{text}#{reset}" }
        when nil
          ->(text) { text }
        end

        information = [
          e.action,
          e.type,
          e.name,
        ].map{|i| colour_mod.call(i) }

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

        coloured_entries << information.compact
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

    def reset
      "\x1b[0m"
    end

    def entry_to_struct(action, entry, hosted_zone, parent_entry = nil)
      value1_highlight = if parent_entry
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

      value2_highlight = if parent_entry
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
        Entry.new(action, entry.type, entry.name,
                  entry.value, value1_highlight,
                  entry.ttl, value2_highlight,
                  hosted_zone.name)
      when SprinkleDNS::HostedZoneAlias
        Entry.new(action, entry.type, entry.name,
                  entry.target_hosted_zone_id, value1_highlight,
                  entry.target_dns_name, value2_highlight,
                  hosted_zone.name)
      end
    end
  end
end
