# require 'fog'

# def batch(zone_domain)
#   change_batch_options = [
#     {
#       :action => "UPSERT",
#       :name => "#{zone_domain}",
#       :type => "A",
#       :ttl => 60,
#       :resource_records => [ '88.80.188.142' ]
#     },
#     {
#       :action => "UPSERT",
#       :name => "assets.#{zone_domain}",
#       :type => "A",
#       :ttl => 60,
#       :resource_records => [ '88.80.188.142' ]
#     },
#     {
#       :action => "UPSERT",
#       :name => "streamy.#{zone_domain}",
#       :type => "A",
#       :ttl => 60,
#       :resource_records => [ '198.211.96.200' ]
#     },
#   ]
# end

# $dns = Fog::DNS.new({
#   provider:              'AWS',
#   aws_access_key_id:     ACCESS_KEY_ID,
#   aws_secret_access_key: SECRET_ACCESS_KEY,
# })

# def get_current_zones
#   zones = {}
#   $dns.zones.map do |zone|
#     zones[zone.domain] = zone.id
#   end
#   zones
# end

# created_zones = get_current_zones
# #wanted_zones  = ['kaspergrubbe.dk.', 'kaspergrubbe.com.']

# wanted_zones.each do |wanted_zone|
#   if created_zones[wanted_zone].nil?
#     $dns.create_hosted_zone(wanted_zone)
#     puts "Created #{wanted_zone}"
#   else
#     puts "Exists #{wanted_zone}"
#   end
# end

# # ALL WANTED ZONES EXISTS AT THIS POINT
# ##########################################################
# zones = get_current_zones

# zones.each do |zone_domain, zone_id|
#   batch = batch(zone_domain)

#   $dns.change_resource_record_sets(zone_id, batch)
# end


require 'sprinkle_dns'

c = SprinkleDNS::AwsDNS.new(ACCESS_KEY_ID, SECRET_ACCESS_KEY)
s = SprinkleDNS::Client.new(1,2)
s.entry("A",  'beta.kaspergrubbe.com',   '88.80.188.142', 360)
s.entry("A",  'kaspergrubbe.com',        '88.80.188.142', 60)
s.entry("A",  'assets.kaspergrubbe.com', '88.80.188.142', 60)
s.entry("MX", 'mail.kaspergrubbe.com',   ['10 mailserver.example.com', '20 mailserver2.example.com'], 300)
s.entry("MX", 'main.kaspergrubbe.com',   ['10 mailserver.example.com'], 300)
s.entry("A",  'streamy.kaspergrubbe.com.', '198.211.96.200', 60)

s.entry("A",   'kaspergrubbe.dk', '88.80.188.142', 60)
s.entry("TXT", 'mesmtp._domainkey.kaspergrubbe.dk.', "\"v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDXbFGl/d7coaDUSBEm1VC32S1F957iwCLawI5mEEp++BzWvmy4Iw03jDohgvX5tPNKSDwwYhzZR+TIdrJZV1lWwQn/ym/QNnjpiMGGJtOrRxFj3TayrgJ87gS8O/1DIeVHmAOB0wX5fbdYGVgzCCznhxY54oeUfh39fluKHrB1owIDAQAB\"", 300)
s.entry("A",   'assets.kaspergrubbe.dk', '88.80.188.142', 60)
s.entry("A",   'streamy.kaspergrubbe.dk', '198.211.96.200', 60)



require 'pry'; binding.pry
raise lol

require 'diff_matcher'
DiffMatcher::difference(s.hosted_zones, c.hosted_zones, opts={})
