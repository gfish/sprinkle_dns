require 'spec_helper'

RSpec.describe SprinkleDNS::HostedZoneDomain do
  it "should zone properly" do
    expect( SprinkleDNS::HostedZoneDomain::parse('servnice.com')                   ).to eq 'servnice.com.'
    expect( SprinkleDNS::HostedZoneDomain::parse('servnice.com.')                  ).to eq 'servnice.com.'
    expect( SprinkleDNS::HostedZoneDomain::parse('servnice.co.uk')                 ).to eq 'servnice.co.uk.'
    expect( SprinkleDNS::HostedZoneDomain::parse('www.billetto.co.uk')             ).to eq 'billetto.co.uk.'
    expect( SprinkleDNS::HostedZoneDomain::parse('*.billetto.co.uk')               ).to eq 'billetto.co.uk.'
    expect( SprinkleDNS::HostedZoneDomain::parse('mesmtp._domainkey.servnice.com') ).to eq 'servnice.com.'
  end
end
