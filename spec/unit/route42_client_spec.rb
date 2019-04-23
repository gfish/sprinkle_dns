require 'spec_helper'

RSpec.describe SprinkleDNS::Route42Client do
  context "#fetch" do
    it "should return empty list when given empty array" do
      hz = SprinkleDNS::HostedZone.new('billetto.se.')
      en = entry("A", "beta.billetto.se", '88.80.188.143', 60, hz.name)
      hz.add_or_update_hosted_zone_entry(en)
      c42 = SprinkleDNS::Route42Client.new([en])

      expect(c42.fetch_hosted_zones).to eq []
      expect(c42.fetch_hosted_zones(filter: [])).to eq []
    end

    it "should initialize correctly" do
      hz = SprinkleDNS::HostedZone.new('billetto.se.')
      en = entry("A", "beta.billetto.se", '88.80.188.143', 60, hz.name)
      hz.add_or_update_hosted_zone_entry(en)
      c42 = SprinkleDNS::Route42Client.new([hz])

      expect(en.persisted?).to be false
      c42.fetch_hosted_zones(filter: [hz.name])
      expect(en.persisted?).to be true
    end

    it "should filter correctly" do
      hosted_zones = []

      hzdk = SprinkleDNS::HostedZone.new('billetto.dk.')

      e1 = entry("A", "beta.billetto.dk.", '88.80.188.143', 60, hzdk.name)
      e2 = entry("A", "alph.billetto.dk.", '88.80.188.144', 60, hzdk.name)
      e3 = entry("A", "lolp.billetto.dk.", '88.80.188.145', 60, hzdk.name)

      [e1, e2, e3].each do |entry|
        hzdk.add_or_update_hosted_zone_entry(entry)
      end

      hosted_zones << hzdk

      hzse = SprinkleDNS::HostedZone.new('billetto.se.')

      e4 = entry("A", "beta.billetto.se", '88.80.188.143', 60, hzse.name)
      e5 = entry("A", "alph.billetto.se", '88.80.188.144', 60, hzse.name)
      e6 = entry("A", "lolp.billetto.se", '88.80.188.145', 60, hzse.name)

      [e4, e5, e6].each do |entry|
        hzse.add_or_update_hosted_zone_entry(entry)
      end

      hosted_zones << hzse

      c42 = SprinkleDNS::Route42Client.new(hosted_zones)
      expect(c42.fetch_hosted_zones(filter: ['billetto.dk.', 'billetto.se.'])).to include(hzdk, hzse)
      expect(c42.fetch_hosted_zones(filter: ['billetto.dk.'])).to include(hzdk)
      expect(c42.fetch_hosted_zones(filter: ['billetto.se.'])).to include(hzse)
    end
  end
end
