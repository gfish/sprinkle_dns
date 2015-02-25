require 'spec_helper'

RSpec.describe SprinkleDNS::ZoneDomain do
  it "should zone properly" do
    expect( SprinkleDNS::ZoneDomain::parse('servnice.com')                   ).to eq 'servnice.com.'
    expect( SprinkleDNS::ZoneDomain::parse('servnice.com.')                  ).to eq 'servnice.com.'
    expect( SprinkleDNS::ZoneDomain::parse('servnice.co.uk')                 ).to eq 'servnice.co.uk.'
    expect( SprinkleDNS::ZoneDomain::parse('www.billetto.co.uk')             ).to eq 'billetto.co.uk.'
    expect( SprinkleDNS::ZoneDomain::parse('*.billetto.co.uk')               ).to eq 'billetto.co.uk.'
    expect( SprinkleDNS::ZoneDomain::parse('mesmtp._domainkey.servnice.com') ).to eq 'servnice.com.'
  end
end
