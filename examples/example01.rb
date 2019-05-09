require 'sprinkle_dns'

# require_relative '../test_perms'
# client = SprinkleDNS::Route53Client.new(ACCESS_KEY_ID, SECRET_ACCESS_KEY)

require 'sprinkle_dns/providers/mock_client'
hz = SprinkleDNS::HostedZone.new('test.colourful.com.')
pe01 = SprinkleDNS::HostedZoneEntry.new('A', 'noref.test.colourful.com.', Array.wrap('80.80.80.80'), 3600, hz.name)
pe02 = SprinkleDNS::HostedZoneEntry.new('A', 'updateme.test.colourful.com.', Array.wrap('80.80.80.80'), 3600, hz.name)
pe03 = SprinkleDNS::HostedZoneEntry.new('TXT', 'txt.test.colourful.com.', %Q{"#{Time.now.to_i}"}, 60, hz.name)
pe04 = SprinkleDNS::HostedZoneEntry.new('A', 'nochange.test.colourful.com.', Array.wrap('80.80.80.80'), 60, hz.name)
sleep(1)
# We are emulating that these records are already live, mark them as persisted
[pe01, pe02, pe03, pe04].each do |persisted|
  persisted.persisted!
  hz.resource_record_sets << persisted
end

client = SprinkleDNS::MockClient.new([hz])
sdns = SprinkleDNS::Client.new(client, delete: true, force: true)

sdns.entry('A', 'noref.test.billetto.com.', '127.0.0.1', 7200, 'test.billetto.com')
sdns.alias('A', 'www.test.billetto.com', 'Z215JYRZR1TBD5', 'dualstack.mothership-prod-elb-546580691.eu-central-1.elb.amazonaws.com', 'test.billetto.com')
sdns.entry('A', 'updateme.test.billetto.com.', '90.90.90.90', 7200, 'test.billetto.com')
sdns.entry('TXT', 'txt.test.billetto.com', %Q{"#{Time.now.to_i}"}, 60, 'test.billetto.com')
sdns.entry('A', 'nochange.test.billetto.com.', '80.80.80.80', 60, 'test.billetto.com')

existing_hosted_zones, _ = sdns.sprinkle!

# ------------------------------------------------------------------------------------------
# ##########################################################################################
# ------------------------------------------------------------------------------------------

sdns = SprinkleDNS::Client.new(client, delete: true, force: true)

sdns.entry('A', 'www.test.billetto.com', '90.90.90.90', 7200, 'test.billetto.com')
sdns.entry('A', 'updateme.test.billetto.com.', '90.90.90.90', 7200, 'test.billetto.com')
#sdns.entry('TXT', 'txt.test.billetto.com', %Q{"#{Time.now.to_i}"}, 60, 'test.billetto.com')
sdns.entry('A', 'nochange.test.billetto.com.', '80.80.80.80', 60, 'test.billetto.com')

sdns.entry("MX", 'test.billetto.com', ['1 aspmx.l.google.com',
                          '5 alt1.aspmx.l.google.com',
                          '5 alt2.aspmx.l.google.com',
                          '10 aspmx2.googlemail.com',
                          '10 aspmx3.googlemail.com'], 60, 'test.billetto.com')

existing_hosted_zones, _ = sdns.sprinkle!
