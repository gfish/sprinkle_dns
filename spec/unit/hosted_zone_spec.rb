require 'spec_helper'

RSpec.describe SprinkleDNS::HostedZone do
  it 'should correctly calculate a compile_change_batch' do
    hz = SprinkleDNS::HostedZone.new('test.billetto.com.')

    hze01 = SprinkleDNS::HostedZoneEntry.new('A', 'www.test.billetto.com.', '80.80.22.22', 60, 'test.billetto.com.')
    hze02 = SprinkleDNS::HostedZoneEntry.new('A', 'foo.test.billetto.com.', '80.80.23.23', 70, 'test.billetto.com.')
    hze03 = SprinkleDNS::HostedZoneEntry.new('A', 'bar.test.billetto.com.', '80.80.24.24', 80, 'test.billetto.com.')

    [hze01, hze02, hze03].each do |hze|
      hz.add_or_update_hosted_zone_entry(hze)
    end

    expect(hz.compile_change_batch).to eq([
      {:action=>"CREATE", :resource_record_set=>{:name=>"www.test.billetto.com.", :type=>"A", :ttl=>60, :resource_records=>[{:value=>"80.80.22.22"}]}},
      {:action=>"CREATE", :resource_record_set=>{:name=>"foo.test.billetto.com.", :type=>"A", :ttl=>70, :resource_records=>[{:value=>"80.80.23.23"}]}},
      {:action=>"CREATE", :resource_record_set=>{:name=>"bar.test.billetto.com.", :type=>"A", :ttl=>80, :resource_records=>[{:value=>"80.80.24.24"}]}},
    ])
  end

  context "overwrite an entry" do
    it 'should correctly replace an entry if not persisted' do
      hz = SprinkleDNS::HostedZone.new('test.billetto.com.')

      hz_entry = SprinkleDNS::HostedZoneEntry.new('A', 'www.test.billetto.com.', '80.80.22.22', 60, 'test.billetto.com.')
      expect(hz_entry.persisted?).to eq false
      hz_alias = SprinkleDNS::HostedZoneAlias.new('A', 'www.test.billetto.com.', 'Z215JYRZR1TBD5', 'dualstack.mothership-test-elb-546580691.eu-central-1.elb.amazonaws.com', 'test.billetto.com.')
      expect(hz_alias.persisted?).to eq false

      hz.add_or_update_hosted_zone_entry(hz_entry)
      expect(hz.resource_record_sets).to include(hz_entry)
      expect(hz.resource_record_sets.size).to eq 1

      hz.add_or_update_hosted_zone_entry(hz_alias)
      expect(hz.resource_record_sets).to include(hz_alias)
      expect(hz.resource_record_sets).not_to include(hz_entry)
      expect(hz.resource_record_sets.size).to eq 1
    end

    it 'should use #new_value if persisted' do
      hz = SprinkleDNS::HostedZone.new('test.billetto.com.')

      hz_entry = SprinkleDNS::HostedZoneEntry.new('A', 'www.test.billetto.com.', '80.80.22.22', 60, 'test.billetto.com.')
      hz_alias = SprinkleDNS::HostedZoneAlias.new('A', 'www.test.billetto.com.', 'Z215JYRZR1TBD5', 'dualstack.mothership-test-elb-546580691.eu-central-1.elb.amazonaws.com', 'test.billetto.com.')

      hz_entry.persisted!

      hz.add_or_update_hosted_zone_entry(hz_entry)
      expect(hz.resource_record_sets).to include(hz_entry)
      expect(hz.resource_record_sets.size).to eq 1

      hz.add_or_update_hosted_zone_entry(hz_alias)
      expect(hz.resource_record_sets).not_to include(hz_alias)
      expect(hz.resource_record_sets.size).to eq 1
      expect(hz.resource_record_sets.first.new_entry).to eq hz_alias
    end
  end

  context "overwrite an alias" do
    it 'should correctly replace an alias if not persisted' do
      hz = SprinkleDNS::HostedZone.new('test.billetto.com.')

      hz_alias = SprinkleDNS::HostedZoneAlias.new('A', 'www.test.billetto.com.', 'Z215JYRZR1TBD5', 'dualstack.mothership-test-elb-546580691.eu-central-1.elb.amazonaws.com', 'test.billetto.com.')
      expect(hz_alias.persisted?).to eq false
      hz_entry = SprinkleDNS::HostedZoneEntry.new('A', 'www.test.billetto.com.', '80.80.22.22', 60, 'test.billetto.com.')
      expect(hz_entry.persisted?).to eq false

      hz.add_or_update_hosted_zone_entry(hz_alias)
      expect(hz.resource_record_sets).to include(hz_alias)
      expect(hz.resource_record_sets.size).to eq 1

      hz.add_or_update_hosted_zone_entry(hz_entry)
      expect(hz.resource_record_sets).to include(hz_entry)
      expect(hz.resource_record_sets).not_to include(hz_alias)
      expect(hz.resource_record_sets.size).to eq 1
    end

    it 'should use #new_value if persisted' do
      hz = SprinkleDNS::HostedZone.new('test.billetto.com.')

      hz_entry = SprinkleDNS::HostedZoneEntry.new('A', 'www.test.billetto.com.', '80.80.22.22', 60, 'test.billetto.com.')
      hz_alias = SprinkleDNS::HostedZoneAlias.new('A', 'www.test.billetto.com.', 'Z215JYRZR1TBD5', 'dualstack.mothership-test-elb-546580691.eu-central-1.elb.amazonaws.com', 'test.billetto.com.')

      hz_entry.persisted!

      hz.add_or_update_hosted_zone_entry(hz_entry)
      expect(hz.resource_record_sets).to include(hz_entry)
      expect(hz.resource_record_sets.size).to eq 1

      hz.add_or_update_hosted_zone_entry(hz_alias)
      expect(hz.resource_record_sets).not_to include(hz_alias)
      expect(hz.resource_record_sets.size).to eq 1
      expect(hz.resource_record_sets.first.new_entry).to eq hz_alias
    end
  end
end
