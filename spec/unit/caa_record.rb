require 'spec_helper'

RSpec.describe "CAA-records" do
  it 'should allow for CAA records' do
    hz = SprinkleDNS::HostedZone.new('colourful.com.')
    e1 = SprinkleDNS::HostedZoneEntry.new('A', 'colourful.com.', Array.wrap('80.80.80.80'), 3600, hz.name)
    e1.persisted!
    hz.resource_record_sets << e1

    client = SprinkleDNS::MockClient.new([hz])
    sdns = SprinkleDNS::Client.new(client, dry_run: false, delete: true, force: true)

    sdns.entry('A', 'colourful.com', '80.80.80.80', 3600)
    sdns.entry('CAA', 'colourful.com', '0 issue "letsencrypt.org"', 3600)

    existing_hosted_zones, _ = sdns.sprinkle!

    shz = client.fetch_hosted_zones(filter: [hz.name]).first

    rrs = shz.resource_record_sets.select{|rrs| rrs.type == 'CAA' && rrs.name == 'colourful.com.'}.first
    expect(rrs.ttl).to eq 3600
    expect(rrs.value).to eq ['0 issue "letsencrypt.org"']
  end
end
