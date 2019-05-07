require 'sprinkle_dns'

require_relative 'test_perms'
client = SprinkleDNS::Route53Client.new(ACCESS_KEY_ID, SECRET_ACCESS_KEY)

25.times do |retry_count|
  sdns = SprinkleDNS::Client.new(client, delete: true, force: true)

  sdns.entry('A', 'www.mxtest.billetto.com', '90.90.90.90', 7200, 'mxtest.billetto.com')
  sdns.entry('A', 'updateme.mxtest.billetto.com.', '90.90.90.90', 7200, 'mxtest.billetto.com')
  #sdns.entry('TXT', 'txt.mxtest.billetto.com', %Q{"#{Time.now.to_i}"}, 60, 'mxtest.billetto.com')
  sdns.entry('A', 'nochange.mxtest.billetto.com.', '80.80.80.80', 60, 'mxtest.billetto.com')

  sdns.entry("MX", 'mxtest.billetto.com', ['1 aspmx.l.google.com',
                            '5 alt1.aspmx.l.google.com',
                            '5 alt2.aspmx.l.google.com',
                            '10 aspmx2.googlemail.com',
                            '10 aspmx3.googlemail.com'], 60, 'mxtest.billetto.com')

  existing_hosted_zones, _ = sdns.sprinkle!

  sleep_time = (retry_count ** 4) + 15 + (rand(30) * (retry_count + 1))
  sleep_time_time = Time.now + sleep_time
  puts "Sleeping #{sleep_time} seconds until #{sleep_time_time}"
  puts "------------------------------------------------------------------------------------"
  sleep sleep_time
end
