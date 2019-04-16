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

    expect(sdns.wanted_zones.count).to eq 2
    expect(sdns.wanted_zones['kaspergrubbe.com.']).to be_truthy
    expect(sdns.wanted_zones['es.kaspergrubbe.com.']).to be_truthy

    expect(sdns.wanted_zones['kaspergrubbe.com.'].count).to eq 6
    expect(sdns.wanted_zones['es.kaspergrubbe.com.'].count).to eq 2
  end

  it 'should support alias records' do
    r53c = SprinkleDNS::Route53Client.new('1','2')
    sdns = SprinkleDNS::Client.new(r53c)

    sdns.entry('A', 'billetto.com',     '88.80.80.80', 60)
    sdns.alias('A', 'www.billetto.com', 'Z215JYRZR1TBD5', 'dualstack.mothership-prod-elb-546580691.eu-central-1.elb.amazonaws.com')

    expect(sdns.wanted_zones.count).to eq 1
    expect(sdns.wanted_zones['billetto.com.']).to be_truthy
    expect(sdns.wanted_zones['billetto.com.'].count).to eq 2
  end

  it 'should allow overwrites' do
    r53c = SprinkleDNS::Route53Client.new('1','2')
    sdns = SprinkleDNS::Client.new(r53c)

    ['billetto.at', 'billetto.io', 'billetto.my'].each do |domain|
      sdns.entry('A', domain, '88.80.80.80', 60)
      sdns.entry('A', "www.#{domain}", '88.80.80.80', 60)
    end
    # Overwrite and null-route to localhost
    sdns.entry('A', 'billetto.at', '127.0.0.1', 60)

    pending
    raise
  end

  it 'should allow overwrites of alias' do
    r53c = SprinkleDNS::Route53Client.new('1','2')
    sdns = SprinkleDNS::Client.new(r53c)

    sdns.entry('A', "billetto.pl", '88.80.80.80', 60)
    sdns.alias('A', 'billetto.pl', 'Z215JYRZR1TBD5', 'dualstack.mothership-prod-elb-546580691.eu-central-1.elb.amazonaws.com')

    pending
    raise
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
