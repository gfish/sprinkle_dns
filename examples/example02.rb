require 'sprinkle_dns'
require 'sprinkle_dns/providers/mock_client'

hz01 = SprinkleDNS::HostedZone.new('colourful.co.uk.')
pe01 = SprinkleDNS::HostedZoneEntry.new('A', 'noref.colourful.co.uk.', Array.wrap('80.80.80.80'), 3600, hz01.name)
pe02 = SprinkleDNS::HostedZoneEntry.new('A', 'updateme.colourful.co.uk.', Array.wrap('80.80.80.80'), 3600, hz01.name)
pe03 = SprinkleDNS::HostedZoneEntry.new('TXT', 'txt.colourful.co.uk.', %Q{"#{Time.now.to_i}"}, 60, hz01.name)
pe04 = SprinkleDNS::HostedZoneEntry.new('A', 'unchanged.colourful.co.uk.', Array.wrap('80.80.80.80'), 60, hz01.name)

# We are emulating that these records are already live, mark them as persisted
[pe01, pe02, pe03, pe04].each do |persisted|
  persisted.persisted!
  hz01.resource_record_sets << persisted
end

hz02 = SprinkleDNS::HostedZone.new('colorful.com.')
pe05 = SprinkleDNS::HostedZoneEntry.new('A', 'noref.colorful.com.', Array.wrap('80.80.80.80'), 3600, hz02.name)
pe06 = SprinkleDNS::HostedZoneEntry.new('A', 'updateme.colorful.com.', Array.wrap('80.80.80.80'), 3600, hz02.name)
pe07 = SprinkleDNS::HostedZoneEntry.new('TXT', 'txt.colorful.com.', %Q{"#{Time.now.to_i}"}, 60, hz02.name)
pe08 = SprinkleDNS::HostedZoneEntry.new('A', 'nochange.colorful.com.', Array.wrap('80.80.80.80'), 60, hz02.name)

# We are emulating that these records are already live, mark them as persisted
[pe05, pe06, pe07, pe08].each do |persisted|
  persisted.persisted!
  hz02.resource_record_sets << persisted
end

hz03 = SprinkleDNS::HostedZone.new('kolorowy.pl.')
pe09 = SprinkleDNS::HostedZoneEntry.new('A', 'noref.kolorowy.pl.', Array.wrap('80.80.80.80'), 3600, hz03.name)
pe10 = SprinkleDNS::HostedZoneEntry.new('A', 'updateme.kolorowy.pl.', Array.wrap('80.80.80.80'), 3600, hz03.name)
pe11 = SprinkleDNS::HostedZoneEntry.new('TXT', 'txt.kolorowy.pl.', %Q{"#{Time.now.to_i}"}, 60, hz03.name)
pe12 = SprinkleDNS::HostedZoneEntry.new('A', 'nochange.kolorowy.pl.', Array.wrap('80.80.80.80'), 60, hz03.name)

# We are emulating that these records are already live, mark them as persisted
[pe09, pe10, pe11, pe12].each do |persisted|
  persisted.persisted!
  hz03.resource_record_sets << persisted
end

client = SprinkleDNS::MockClient.new([hz01, hz02, hz03])
sdns = SprinkleDNS::Client.new(client, force: true, diff: true, delete: true, interactive_progress: true)

sdns.entry('A', 'colourful.co.uk', '90.90.90.90', 3600)
sdns.entry('A', 'updateme.colourful.co.uk', '90.90.90.90', 3600)
sdns.entry('A', 'unchanged.colourful.co.uk', '80.80.80.80', 60)
sdns.entry('TXT', 'txt.colourful.co.uk', %Q{"#{Time.now.to_i+1}"}, 60)
sdns.entry('A', 'colorful.com.', '80.80.80.80', 3601)
sdns.entry('A', 'kolorowy.pl.', '80.80.80.80', 3601)

existing_hosted_zones, _ = sdns.sprinkle!

puts "--------------------------------------------------------------------------------------------"

client = SprinkleDNS::MockClient.new([hz02, hz01, hz03])
sdns = SprinkleDNS::Client.new(client, delete: false, interactive_progress: false, force: false)

sdns.entry('A', 'colourful.co.uk', '90.90.90.90', 3601)
sdns.entry('A', 'colorful.com.', '80.80.80.80', 3601)
sdns.entry('A', 'kolorowy.pl.', '80.80.80.80', 3601)

existing_hosted_zones, _ = sdns.sprinkle!
