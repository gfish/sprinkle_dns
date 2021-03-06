require 'spec_helper'

RSpec.describe SprinkleDNS::CLI::HostedZoneDiff do
  it 'should print' do
    hz = SprinkleDNS::HostedZone.new('test.colourful.com.')
    pe01 = SprinkleDNS::HostedZoneEntry.new('A', 'noref.test.colourful.com.', Array.wrap('80.80.80.80'), 3600, hz.name)
    pe02 = SprinkleDNS::HostedZoneEntry.new('A', 'updateme.test.colourful.com.', Array.wrap('80.80.80.80'), 3600, hz.name)
    pe03 = SprinkleDNS::HostedZoneEntry.new('TXT', 'txt.test.colourful.com.', %Q{"#{Time.now.to_i}"}, 60, hz.name)
    pe04 = SprinkleDNS::HostedZoneEntry.new('A', 'nochange.test.colourful.com.', Array.wrap('80.80.80.80'), 60, hz.name)

    # We are emulating that these records are already live, mark them as persisted
    [pe01, pe02, pe03, pe04].each do |persisted|
      persisted.persisted!
      hz.resource_record_sets << persisted
    end

    client = SprinkleDNS::MockClient.new([hz])
    sdns   = SprinkleDNS::Client.new(client, dry_run: true, diff: false)

    sdns.entry('A', 'updateme.test.colourful.com.', '90.90.90.90', 7200, 'test.colourful.com')
    sdns.entry('TXT', 'txt.test.colourful.com', %Q{"#{Time.now.to_i+10}"}, 60, 'test.colourful.com')
    sdns.entry('A', 'nochange.test.colourful.com.', '80.80.80.80', 60, 'test.colourful.com')

    existing_hosted_zones, _ = sdns.sprinkle!

    SprinkleDNS::CLI::HostedZoneDiff.new.diff(existing_hosted_zones, [], sdns.config).each do |line|
      puts line.join(' ')
    end
  end
end
