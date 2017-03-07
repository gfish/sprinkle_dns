require 'sprinkle_dns'

client = SprinkleDNS::Route53Client.new(ACCESS_KEY_ID, SECRET_ACCESS_KEY)
sdns   = SprinkleDNS::Client.new(client)

sdns.entry('A',   'beta.kaspergrubbe.com',   '88.80.188.142', 360)
sdns.entry('A',   'kaspergrubbe.com',        '88.80.188.142', 60)
sdns.entry('A',   'assets.kaspergrubbe.com', '88.80.188.142', 60)
sdns.entry('MX',  'mail.kaspergrubbe.com',   ['10 mailserver.example.com', '20 mailserver2.example.com'], 300)
sdns.entry('MX',  'main.kaspergrubbe.com',   ['10 mailserver.example.com'], 300)
sdns.entry('A',   'streamy.kaspergrubbe.com.', '198.211.96.200', 60)
sdns.entry('A',   'kaspergrubbe.dk', '88.80.188.142', 60)
sdns.entry('TXT', 'mesmtp._domainkey.kaspergrubbe.dk.', "\"v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDXbFGl/d7coaDUSBEm1VC32S1F957iwCLawI5mEEp++BzWvmy4Iw03jDohgvX5tPNKSDwwYhzZR+TIdrJZV1lWwQn/ym/QNnjpiMGGJtOrRxFj3TayrgJ87gS8O/1DIeVHmAOB0wX5fbdYGVgzCCznhxY54oeUfh39fluKHrB1owIDAQAB\"", 300)
sdns.entry('A',   'assets.kaspergrubbe.dk', '88.80.188.142', 60)
sdns.entry('A',   'streamy.kaspergrubbe.dk', '198.211.96.200', 60)

sdns.sprinkle!
