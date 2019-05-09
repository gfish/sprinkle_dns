require 'spec_helper'

RSpec.describe SprinkleDNS::Client do
  it 'should parse and setup' do
    r53c = SprinkleDNS::Route53Client.new('1','2')
    sdns = SprinkleDNS::Client.new(r53c)

    sdns.entry('A',     'kaspergrubbe.com',             '88.80.80.80', 60)
    sdns.entry('A',     'assets.kaspergrubbe.com',      '88.80.80.80', 60)
    sdns.entry('MX',    'mail.kaspergrubbe.com',        ['10 mailserver.example.com', '20 mailserver2.example.com'], 300)
    sdns.entry('MX',    'main.kaspergrubbe.com',        ['10 mailserver.example.com'], 300)
    sdns.entry('A',     'streamy.kaspergrubbe.com.',    '198.211.96.200', 60)
    sdns.entry('A',     'blog.kaspergrubbe.com',        '198.211.96.200', 60)

    sdns.entry('CNAME', 'www.es.kaspergrubbe.com',      "#{Time.now.to_i}.example.com.", 42, 'es.kaspergrubbe.com')
    sdns.entry('CNAME', 'staging.es.kaspergrubbe.com.', "#{Time.now.to_i}.example.com.", 42, 'es.kaspergrubbe.com.')

    expect(sdns.wanted_hosted_zones.count).to eq 2
    expect(sdns.wanted_hosted_zones.select{|whz| whz.name == 'kaspergrubbe.com.'}.first).to be_truthy
    expect(sdns.wanted_hosted_zones.select{|whz| whz.name == 'es.kaspergrubbe.com.'}.first).to be_truthy

    expect(sdns.wanted_hosted_zones.select{|whz| whz.name == 'kaspergrubbe.com.'}.first.resource_record_sets.count).to eq 6
    expect(sdns.wanted_hosted_zones.select{|whz| whz.name == 'es.kaspergrubbe.com.'}.first.resource_record_sets.count).to eq 2
  end

  it 'should support alias records' do
    r53c = SprinkleDNS::Route53Client.new('1','2')
    sdns = SprinkleDNS::Client.new(r53c)

    sdns.entry('A', 'billetto.com',     '88.80.80.80', 60)
    sdns.alias('A', 'www.billetto.com', 'Z215JYRZR1TBD5', 'dualstack.mothership-prod-elb-546580691.eu-central-1.elb.amazonaws.com')

    expect(sdns.wanted_hosted_zones.count).to eq 1
    expect(sdns.wanted_hosted_zones.select{|whz| whz.name == 'billetto.com.'}.first).to be_truthy
    expect(sdns.wanted_hosted_zones.select{|whz| whz.name == 'billetto.com.'}.first.resource_record_sets.count).to eq 2
  end

  context "overwrites" do
    it 'should allow overwrites for a-records' do
      r53c = SprinkleDNS::Route53Client.new('1','2')
      sdns = SprinkleDNS::Client.new(r53c)

      ['billetto.at', 'billetto.io', 'billetto.my'].each do |domain|
        sdns.entry('A', domain, '88.80.80.80', 60)
        sdns.entry('A', "www.#{domain}", '88.80.80.80', 60)
      end
      # Overwrite and null-route to localhost
      sdns.entry('A', 'billetto.at', '127.0.0.1', 70)

      hz = sdns.wanted_hosted_zones.select{|hz| hz.name == 'billetto.at.'}.first
      rrs = hz.resource_record_sets.select{|rrs| rrs.type == 'A' && rrs.name == 'billetto.at.'}.first

      expect(rrs.ttl).to eq 70
      expect(rrs.value).to eq ["127.0.0.1"]
    end

    it 'should allow overwrites for aliases' do
      r53c = SprinkleDNS::Route53Client.new('1','2')
      sdns = SprinkleDNS::Client.new(r53c)

      ['billetto.at', 'billetto.io', 'billetto.my'].each do |domain|
        sdns.alias('A', domain, 'Z215JYRZR1TBD5', 'dualstack.mothership-prod-elb-546580691.eu-central-1.elb.amazonaws.com')
      end
      sdns.alias('A', 'billetto.at', 'X317JYRZR1TBD5', 'triplestack.mothership-prod-elb-546580691.eu-central-1.elb.amazonaws.com')

      hz = sdns.wanted_hosted_zones.select{|hz| hz.name == 'billetto.at.'}.first
      rrs = hz.resource_record_sets.select{|rrs| rrs.type == 'A' && rrs.name == 'billetto.at.'}.first

      expect(rrs.target_hosted_zone_id).to eq 'X317JYRZR1TBD5'
      expect(rrs.target_dns_name).to eq 'triplestack.mothership-prod-elb-546580691.eu-central-1.elb.amazonaws.com.'
    end

    it 'should allow overwrites of an a-record with an alias' do
      r53c = SprinkleDNS::Route53Client.new('1','2')
      sdns = SprinkleDNS::Client.new(r53c)

      sdns.entry('A', "billetto.pl", '88.80.80.80', 60)
      sdns.alias('A', 'billetto.pl', 'Z215JYRZR1TBD5', 'dualstack.mothership-prod-elb-546580691.eu-central-1.elb.amazonaws.com')

      hz = sdns.wanted_hosted_zones.select{|hz| hz.name == 'billetto.pl.'}.first
      rrs = hz.resource_record_sets.select{|rrs| rrs.type == 'A' && rrs.name == 'billetto.pl.'}.first

      expect(rrs.target_hosted_zone_id).to eq 'Z215JYRZR1TBD5'
      expect(rrs.target_dns_name).to eq 'dualstack.mothership-prod-elb-546580691.eu-central-1.elb.amazonaws.com.'
    end

    it 'should allow overwrites of an alias with an a-record' do
      r53c = SprinkleDNS::Route53Client.new('1','2')
      sdns = SprinkleDNS::Client.new(r53c)

      sdns.alias('A', 'billetto.pl', 'Z215JYRZR1TBD5', 'dualstack.mothership-prod-elb-546580691.eu-central-1.elb.amazonaws.com')
      sdns.entry('A', "billetto.pl", '88.80.80.80', 60)

      hz = sdns.wanted_hosted_zones.select{|hz| hz.name == 'billetto.pl.'}.first
      rrs = hz.resource_record_sets.select{|rrs| rrs.type == 'A' && rrs.name == 'billetto.pl.'}.first

      expect(rrs.ttl).to eq 60
      expect(rrs.value).to eq ['88.80.80.80']
    end
  end

  context 'syncing' do
    before(:all) do
      hz = SprinkleDNS::HostedZone.new('billetto.se.')
      en = sprinkle_entry("A", "beta.billetto.se", '88.80.188.143', 60, hz.name)
      hz.add_or_update_hosted_zone_entry(en)

      r42c = SprinkleDNS::MockClient.new([hz])
      @sdns = SprinkleDNS::Client.new(r42c)

      @sdns.entry('A', 'billetto.se', '88.80.80.80', 60)
      @sdns.entry('A', 'beta.billetto.se', '88.80.80.80', 70)
    end

    it 'sprinkle! should return change_requests' do
      _, change_requests = @sdns.sprinkle!

      change_requests.each do |cr|
        expect(cr.in_sync).to eq true
        expect(cr.tries).to eq cr.tries_needed
      end
    end
  end

  context 'delete config option' do
    before(:all) do
      @hz01 = SprinkleDNS::HostedZone.new('colourful.co.uk.')

      e1 = SprinkleDNS::HostedZoneEntry.new('A', 'updateme.colourful.co.uk.', Array.wrap('80.80.80.80'), 3600, @hz01.name)
      e2 = SprinkleDNS::HostedZoneEntry.new('TXT', 'txt.colourful.co.uk.', %Q{"#{Time.now.to_i}"}, 60, @hz01.name)
      e3 = SprinkleDNS::HostedZoneEntry.new('A', 'nochange.colourful.co.uk.', Array.wrap('80.80.80.80'), 60, @hz01.name)
      e4 = SprinkleDNS::HostedZoneEntry.new('A', 'noref.colourful.co.uk.', Array.wrap('80.80.80.80'), 3600, @hz01.name)
      e5 = SprinkleDNS::HostedZoneEntry.new('A', 'www1.colourful.co.uk.', Array.wrap('80.80.80.80'), 60, @hz01.name)
      e6 = SprinkleDNS::HostedZoneEntry.new('A', 'www2.colourful.co.uk.', Array.wrap('80.80.80.80'), 60, @hz01.name)
      e7 = SprinkleDNS::HostedZoneEntry.new('A', 'www3.colourful.co.uk.', Array.wrap('80.80.80.80'), 60, @hz01.name)

      # We are emulating that these records are already live, mark them as persisted
      [e1, e2, e3, e4, e5, e6, e7].each do |persisted|
        persisted.persisted!
        @hz01.resource_record_sets << persisted
      end
    end

    it 'it should not list deletes if delete=false' do
      client = SprinkleDNS::MockClient.new([@hz01])
      sdns = SprinkleDNS::Client.new(client, dry_run: true, delete: false)

      sdns.entry('A', 'updateme.colourful.co.uk', '90.90.90.90', 3601)
      sdns.entry('A', 'addnew.colourful.co.uk', '90.90.90.90', 3601)
      sdns.entry('TXT', 'txt.colourful.co.uk', %Q{"#{Time.now.to_i+1}"}, 60)
      sdns.entry('A', 'nochange.colourful.co.uk.', Array.wrap('80.80.80.80'), 60)

      existing_hosted_zones, _ = sdns.sprinkle!

      expect(existing_hosted_zones.size).to eq 1

      hosted_zone = existing_hosted_zones.first
      policy_service = SprinkleDNS::EntryPolicyService.new(@hz01, sdns.config)
      expect(policy_service.entries_to_delete.size).to eq 0
      expect(policy_service.compile.select{|rrset| rrset[:action] == 'DELETE'}.count).to eq 0
    end

    it 'it should list deletes if delete=true' do
      client = SprinkleDNS::MockClient.new([@hz01])
      sdns = SprinkleDNS::Client.new(client, dry_run: true, delete: true)

      sdns.entry('A', 'updateme.colourful.co.uk', '90.90.90.90', 3601)
      sdns.entry('A', 'addnew.colourful.co.uk', '90.90.90.90', 3601)
      sdns.entry('TXT', 'txt.colourful.co.uk', %Q{"#{Time.now.to_i+1}"}, 60)
      sdns.entry('A', 'nochange.colourful.co.uk.', Array.wrap('80.80.80.80'), 60)

      existing_hosted_zones, _ = sdns.sprinkle!

      expect(existing_hosted_zones.size).to eq 1

      hosted_zone = existing_hosted_zones.first
      policy_service = SprinkleDNS::EntryPolicyService.new(@hz01, sdns.config)
      expect(policy_service.entries_to_delete.size).to eq 4
      expect(policy_service.compile.select{|rrset| rrset[:action] == 'DELETE'}.count).to eq 4
    end
  end

  context 'record validation' do
    it 'should only allow valid string records' do
      valid_records = ['SOA','A','TXT','NS','CNAME','MX','NAPTR','PTR','SRV','SPF','AAAA']

      valid_records.each do |record_type|
        r53c = SprinkleDNS::Route53Client.new('1','2')
        sdns = SprinkleDNS::Client.new(r53c)

        sdns.entry(record_type, 'kaspergrubbe.com', '88.80.80.80')
      end
    end

    it 'should not allow symbols for records' do
      invalid_records = [:SOA, :A, :TXT, :NS, :CNAME, :MX, :NAPTR, :PTR, :SRV, :SPF, :AAAA]

      invalid_records.each do |record_type|
        r53c = SprinkleDNS::Route53Client.new('1','2')
        sdns = SprinkleDNS::Client.new(r53c)

        expect{sdns.entry(record_type, 'kaspergrubbe.com', '88.80.80.80')}.to raise_error(SprinkleDNS::RecordNotAString)
      end
    end

    it 'should not allow other types of records' do
      invalid_records = ['a', 'r', 'p']

      invalid_records.each do |record_type|
        r53c = SprinkleDNS::Route53Client.new('1','2')
        sdns = SprinkleDNS::Client.new(r53c)

        expect{sdns.entry(record_type, 'kaspergrubbe.com', '88.80.80.80')}.to raise_error(SprinkleDNS::RecordNotValid)
      end
    end
  end

  context 'ttl validation' do
    it 'should allow integers' do
      (1..(3600*60)).minmax.each do |ttl|
        r53c = SprinkleDNS::Route53Client.new('1','2')
        sdns = SprinkleDNS::Client.new(r53c)

        sdns.entry('A', 'kaspergrubbe.com', '88.80.80.80', ttl)
      end
    end

    it 'should not allow strings' do
      (1..(3600*60)).minmax.each do |ttl|
        r53c = SprinkleDNS::Route53Client.new('1','2')
        sdns = SprinkleDNS::Client.new(r53c)

        expect{sdns.entry('A', 'kaspergrubbe.com', '88.80.80.80', ttl.to_s)}.to raise_error(SprinkleDNS::TtlNotInteger)
      end
    end
  end
end
