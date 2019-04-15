![SprinkleDNS logo](logos/SDNS.png)

# SprinkleDNS

A diff-based way of managing DNS for people with lots of domains for AWS Route53.

## How

Use plain old Ruby to define your DNS settings:

```ruby
require 'sprinkle_dns'

client = SprinkleDNS::Route53Client.new(ACCESS_KEY_ID, SECRET_ACCESS_KEY)
sdns   = SprinkleDNS::Client.new(client)

sdns.entry('A', 'www.billetto.com', '88.80.188.142', 360)
sdns.entry('A', 'staging.billetto.com', '88.80.188.143', 360)

sdns.sprinkle!
```

Or a more advanced example:

```ruby
require 'sprinkle_dns'

client = SprinkleDNS::Route53Client.new(ACCESS_KEY_ID, SECRET_ACCESS_KEY)
sdns   = SprinkleDNS::Client.new(client)

domains = ['billetto.dk', 'billetto.co.uk', 'billetto.com',  'billetto.se']

domains.each do |domain|
  sdns.entry('A', domain, '88.80.188.142', 360)
  sdns.entry('A', "www.#{domain}", '88.80.188.142', 360)

  s.entry("CNAME", "docs.#{domain}",  'ghs.googlehosted.com', 43200)
  s.entry("CNAME", "mail.#{domain}",  'ghs.googlehosted.com', 43200)
  s.entry("CNAME", "drive.#{domain}", 'ghs.googlehosted.com', 43200)

  s.entry("MX",    domain, ['1 aspmx.l.google.com',
                            '5 alt1.aspmx.l.google.com',
                            '5 alt2.aspmx.l.google.com',
                            '10 aspmx2.googlemail.com',
                            '10 aspmx3.googlemail.com'], 60)
end

# Overwrite on of the domains, to test new loadbalancer
sdns.entry('A', 'billetto.com', '89.81.189.143', 360)

sdns.sprinkle!
```

## Amazon policy

This gem uses the following permissions:

`route53:ListResourceRecordSets` to read records for a hosted zone, `route53:ChangeResourceRecordSets` to change records for a hosted zone, `route53:GetChange` for reading when a change have been applied, `route53:ListHostedZones` for getting a list of hosted zones.

For a "locked down" policy you can use this:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "route53:ListResourceRecordSets",
                "route53:ChangeResourceRecordSets"
            ],
            "Resource": [
                "arn:aws:route53:::hostedzone/Z3EATJAGJWXQE8"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "route53:GetChange",
                "route53:ListHostedZones"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
```

Or you can allow it for all of your hosted zones:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "route53:ListResourceRecordSets",
                "route53:ChangeResourceRecordSets"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "route53:GetChange",
                "route53:ListHostedZones"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
```
