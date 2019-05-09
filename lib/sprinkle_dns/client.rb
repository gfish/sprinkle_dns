require 'sprinkle_dns/exceptions'
require 'sprinkle_dns/config'
require 'sprinkle_dns/hosted_zone'
require 'sprinkle_dns/hosted_zone_domain'
require 'sprinkle_dns/hosted_zone_entry'
require 'sprinkle_dns/hosted_zone_alias'
require 'sprinkle_dns/entry_policy_service'

require 'sprinkle_dns/cli/hosted_zone_diff'
require 'sprinkle_dns/cli/interactive_change_request_printer'
require 'sprinkle_dns/cli/propagated_change_request_printer'

require 'sprinkle_dns/core_ext/array_wrap'
require 'sprinkle_dns/core_ext/zonify'

module SprinkleDNS
  class Client
    attr_reader :wanted_hosted_zones, :config

    def initialize(dns_provider, dry_run: false, diff: true, force: true, delete: false, interactive_progress: true, create_hosted_zones: false, show_untouched: false)
      @config = SprinkleDNS::Config.new(
        dry_run: dry_run,
        diff: diff,
        force: force,
        delete: delete,
        interactive_progress: interactive_progress,
        create_hosted_zones: create_hosted_zones,
        show_untouched: show_untouched,
      )
      @dns_provider = dns_provider
      @wanted_hosted_zones = []

      @progress_printer = if @config.interactive_progress?
        SprinkleDNS::CLI::InteractiveChangeRequestPrinter.new
      else
        SprinkleDNS::CLI::PropagatedChangeRequestPrinter.new
      end
    end

    def entry(type, name, value, ttl = 3600, hosted_zone = nil)
      hosted_zone = find_or_init_hosted_zone(name, hosted_zone)
      name        = zonify!(name)

      if ['CNAME', 'MX'].include?(type)
        value = Array.wrap(value)
        value.map!{|v| zonify!(v)}
      end
      hosted_zone.add_or_update_hosted_zone_entry(HostedZoneEntry.new(type, name, Array.wrap(value), ttl, hosted_zone.name))
    end

    def alias(type, name, hosted_zone_id, dns_name, hosted_zone = nil)
      hosted_zone = find_or_init_hosted_zone(name, hosted_zone)
      name        = zonify!(name)
      dns_name    = zonify!(dns_name)

      hosted_zone.add_or_update_hosted_zone_entry(HostedZoneAlias.new(type, name, hosted_zone_id, dns_name, hosted_zone.name))
    end

    def compare
      existing_hosted_zones = @dns_provider.fetch_hosted_zones(filter: @wanted_hosted_zones.map(&:name))

      # Tell our existing hosted zones about our wanted changes
      existing_hosted_zones.each do |existing_hosted_zone|
        wanted_hosted_zone = @wanted_hosted_zones.find{|whz| whz.name == existing_hosted_zone.name}

        wanted_hosted_zone.resource_record_sets.each do |entry|
          existing_hosted_zone.add_or_update_hosted_zone_entry(entry)
        end
      end

      [@wanted_hosted_zones, existing_hosted_zones]
    end

    def sprinkle!
      wanted_hosted_zones, existing_hosted_zones = compare

      missing_hosted_zone_names = wanted_hosted_zones.map(&:name) - existing_hosted_zones.map(&:name)
      missing_hosted_zones = wanted_hosted_zones.select{|whz| missing_hosted_zone_names.include?(whz.name)}

      if missing_hosted_zones.any? && !@config.create_hosted_zones?
        missing_hosted_zones_error(missing_hosted_zones)
      end

      if @config.diff?
        SprinkleDNS::CLI::HostedZoneDiff.new.diff(existing_hosted_zones, missing_hosted_zones, @config).each do |line|
          puts line.join(' ')
        end
      end

      if @config.dry_run?
        return [existing_hosted_zones, nil]
      end

      hosted_zones = (existing_hosted_zones + missing_hosted_zones)

      unless @config.force?
        changes = hosted_zones.map{|h| SprinkleDNS::EntryPolicyService.new(h, @config)}.collect{|eps| eps.entries_to_change}.sum

        if missing_hosted_zones.any? || changes > 0
          messages = []
          messages << "#{missing_hosted_zones.size} hosted-zone(s) to create" if missing_hosted_zones.any?
          messages << "#{changes} change(s) to make" if changes > 0
          print messages.join(' and ').concat(". Continue? (y/N)")

          case gets.strip
          when 'y', 'Y'
            # continue
          else
            puts ".. exiting!"
            return [hosted_zones, nil]
          end
        else
          puts "No changes to make, everything up to date!"
          puts ".. exiting!"
          return [hosted_zones, nil]
        end
      end

      # Create missing hosted zones
      change_requests_hosted_zones = @dns_provider.create_hosted_zones(missing_hosted_zones)
      if change_requests_hosted_zones.any?
        puts
        puts "Creating hosted zones:"
        @progress_printer.reset!
        begin
          @dns_provider.check_change_requests(change_requests_hosted_zones)
          @progress_printer.draw(change_requests_hosted_zones, 'CREATING', 'CREATED')
        end until change_requests_hosted_zones.all?{|cr| cr.in_sync}
      end

      # Update hosted zones
      change_requests_entries = @dns_provider.change_hosted_zones(hosted_zones, @config)
      if change_requests_entries.any?
        puts
        puts "Updating hosted zones:"
        @progress_printer.reset!
        begin
          @dns_provider.check_change_requests(change_requests_entries)
          @progress_printer.draw(change_requests_entries, 'UPDATING', 'UPDATED')
        end until change_requests_entries.all?{|cr| cr.in_sync}
      end

      change_requests = change_requests_hosted_zones + change_requests_entries

      [hosted_zones, change_requests]
    end

    private

    def find_or_init_hosted_zone(record_name, hosted_zone_name)
      hosted_zone_name ||= HostedZoneDomain::parse(record_name)
      hosted_zone_name   = zonify!(hosted_zone_name)

      wanted_hosted_zone = @wanted_hosted_zones.find{|zone| zone.name == hosted_zone_name}
      if wanted_hosted_zone.nil?
        wanted_hosted_zone = HostedZone.new(hosted_zone_name)
        @wanted_hosted_zones << wanted_hosted_zone
      end

      wanted_hosted_zone
    end

    def missing_hosted_zones_error(missing_hosted_zones)
      error_message = []
      error_message << "There are #{missing_hosted_zones.size} missing hosted zones:"

      missing_hosted_zones.map(&:name).sort.each do |whz|
        error_message << "- #{whz}"
      end

      raise error_message.join("\n")
    end
  end

end
