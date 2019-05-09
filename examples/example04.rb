require 'sprinkle_dns'
require 'sprinkle_dns/providers/mock_client'

client = SprinkleDNS::MockClient.new
sdns = SprinkleDNS::Client.new(client, force: false, diff: true, delete: true, interactive_progress: true, create_hosted_zones: true)

sdns.entry('A', 'colourful.co.uk', '90.90.90.90', 3600)
sdns.entry('A', 'updateme.colourful.co.uk', '90.90.90.90', 3600)
sdns.entry('A', 'unchanged.colourful.co.uk', '80.80.80.80', 60)
sdns.entry('TXT', 'txt.colourful.co.uk', %Q{"#{Time.now.to_i+1}"}, 60)
sdns.entry('A', 'colorful.com.', '80.80.80.80', 3601)
sdns.entry('A', 'kolorowy.pl.', '80.80.80.80', 3601)

existing_hosted_zones, _ = sdns.sprinkle!
