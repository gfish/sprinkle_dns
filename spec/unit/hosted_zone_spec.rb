require 'spec_helper'

RSpec.describe SprinkleDNS::HostedZone do
  it 'should correctly calculate a compile_change_batch' do
    pending

    hz = SprinkleDNS::HostedZone.new('/hostedzone/Z3EATJAGJWXQE8', 'test.billetto.com.')

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

  it 'should correctly overwrite an entry' do
    pending

    hz = SprinkleDNS::HostedZone.new('/hostedzone/Z3EATJAGJWXQE8', 'test.billetto.com.')

    hze = SprinkleDNS::HostedZoneEntry.new('A', 'www.test.billetto.com.', '80.80.22.22', 60, 'test.billetto.com.')
    hza = SprinkleDNS::HostedZoneAlias.new('A', 'www.test.billetto.com.', 'Z215JYRZR1TBD5', 'dualstack.mothership-test-elb-546580691.eu-central-1.elb.amazonaws.com', 'test.billetto.com.')

    [hze, hza].each do |it|
      hz.add_or_update_hosted_zone_entry(it)
    end

    require 'pry'; binding.pry
  end
end
