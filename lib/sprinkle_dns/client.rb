require 'sprinkle_dns/exceptions'
require 'sprinkle_dns/config'
require 'sprinkle_dns/hosted_zone'
require 'sprinkle_dns/hosted_zone_domain'
require 'sprinkle_dns/hosted_zone_entry'
require 'sprinkle_dns/hosted_zone_alias'

require 'sprinkle_dns/cli/hosted_zone_diff'
require 'sprinkle_dns/cli/interactive_change_request_printer'
require 'sprinkle_dns/cli/propagated_change_request_printer'

require 'sprinkle_dns/core_ext/array_wrap'
require 'sprinkle_dns/core_ext/zonify'

module SprinkleDNS
  class Client
    attr_reader :wanted_hosted_zones, :config

    def initialize(dns_provider, dry_run: false, diff: true, force: true, delete: false)
      @config = SprinkleDNS::Config.new(dry_run: dry_run, diff: diff, force: force, delete: delete)
      @dns_provider = dns_provider
      @wanted_hosted_zones = []
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

      hosted_zone.add_or_update_hosted_zone_entry(HostedZoneAlias.new(type, name, hosted_zone_id, dns_name, hosted_zone.name))
    end

    def compare
      existing_hosted_zones = @dns_provider.fetch_hosted_zones(filter: @wanted_hosted_zones.map(&:name))

      # Make sure we have the same amount of zones
      unless existing_hosted_zones.map(&:name) - @wanted_hosted_zones.map(&:name) == []
        error_message = []
        error_message << "We found #{existing_hosted_zones.size} existing zones, but #{@wanted_hosted_zones} was described, exiting!"
        error_message << ""

        error_message << "Existing:"
        existing_hosted_zones.map(&:name).sort.each do |ehz|
          error_message << "- #{ehz}"
        end

        error_message << "Described:"
        @wanted_hosted_zones.map(&:name).sort.each do |whz|
          error_message << "- #{whz}"
        end

        raise error_message.join("\n")
      end

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
      _, existing_hosted_zones = compare

      if @config.diff?
        SprinkleDNS::CLI::HostedZoneDiff.new.diff(existing_hosted_zones).each do |line|
          puts line.join(' ')
        end
      end

      if @config.dry_run?
        return [existing_hosted_zones, nil]
      end

      unless @config.force?
        changes = existing_hosted_zones.collect{|h| h.entries_to_change}.sum
        puts
        print "#{changes} changes to make. Continue? (y/N)"
        case gets.strip
        when 'y', 'Y'
          # continue
        else
          puts ".. exiting!"
          return [existing_hosted_zones, nil]
        end
      end

      change_requests = @dns_provider.change_hosted_zones(existing_hosted_zones, delete: @config.delete?)
      progress_printer = if @config.interactive_progress?
        SprinkleDNS::CLI::InteractiveChangeRequestPrinter.new
      else
        SprinkleDNS::CLI::PropagatedChangeRequestPrinter.new
      end

      begin
        @dns_provider.check_change_requests(change_requests)
        progress_printer.draw(change_requests)
      end until change_requests.all?{|cr| cr.in_sync}

      [existing_hosted_zones, change_requests]
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
  end

end
