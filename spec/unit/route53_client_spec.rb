require 'spec_helper'

RSpec.describe SprinkleDNS::Route53Client do
  RSpec.describe("permissions") do
    it "should throw errors when ACCESS_KEY_ID and SECRET_ACCESS_KEY is revoked" do
      VCR.use_cassette("00-revoked-keys") do
        require_relative '../../testperms'

        client = SprinkleDNS::Route53Client.new(ACCESS_KEY_ID, SECRET_ACCESS_KEY)
        sdns   = SprinkleDNS::Client.new(client)

        sdns.entry('A', 'test.noaccess.billetto.com', '88.80.188.142', 360, 'test.noaccess.billetto.com')
        sdns.sprinkle!

        pending
      end
    end

    it "should throw errors when no permissions at all" do
      VCR.use_cassette("01-test-no-permissions") do
        require_relative '../../testperms'

        client = SprinkleDNS::Route53Client.new(ACCESS_KEY_ID, SECRET_ACCESS_KEY)
        sdns   = SprinkleDNS::Client.new(client)

        sdns.entry('A', 'test.noaccess.billetto.com', '88.80.188.142', 360, 'test.noaccess.billetto.com')
        sdns.sprinkle!

        pending
      end
    end

    it "should throw errors when missing listing resourcerecordsets permissions" do
      # POLICY-EXAMPLE:
      # {
      #   "Version": "2012-10-17",
      #   "Statement": [
      #       {
      #           "Sid": "Stmt1482248073001",
      #           "Effect": "Allow",
      #           "Action": [
      #               "route53:ListHostedZones",
      #               "route53:GetHostedZone"
      #           ],
      #           "Resource": [
      #               "*"
      #           ]
      #       }
      #   ]
      # }

      VCR.use_cassette("02-missing-resourcerecordsets-permissions") do
        require_relative '../../testperms'
        client = SprinkleDNS::Route53Client.new(ACCESS_KEY_ID, SECRET_ACCESS_KEY)
        sdns   = SprinkleDNS::Client.new(client)

        sdns.entry('A', 'test.noaccess.billetto.com', '88.80.188.142', 360, 'test.noaccess.billetto.com')
        sdns.sprinkle!

        pending
      end
    end

    it "should throw errors when missing hosted zone write permissions" do
      # POLICY-EXAMPLE:
      # {
      #   "Version": "2012-10-17",
      #   "Statement": [
      #     {
      #       "Effect": "Allow",
      #       "Action": [
      #         "route53:Get*",
      #         "route53:List*",
      #         "route53:TestDNSAnswer"
      #       ],
      #       "Resource": [
      #         "*"
      #       ]
      #     }
      #   ]
      # }

      VCR.use_cassette("03-missing-hostedzone-write-permissions") do
        require_relative '../../testperms'
        client = SprinkleDNS::Route53Client.new(ACCESS_KEY_ID, SECRET_ACCESS_KEY)
        sdns   = SprinkleDNS::Client.new(client)

        sdns.entry('A', 'test.noaccess.billetto.com', '127.0.0.1', 3600, 'test.noaccess.billetto.com')
        sdns.entry('A', 'kasp.noaccess.billetto.com', '127.0.0.1', 3600, 'test.noaccess.billetto.com')
        sdns.sprinkle!

        pending
      end
    end

    it "should throw not having access to getchange" do
      # POLICY-EXAMPLE:
      # {
      #     "Version": "2012-10-17",
      #     "Statement": [
      #         {
      #             "Sid": "Stmt1482248073001",
      #             "Effect": "Allow",
      #             "Action": [
      #                 "route53:ListHostedZones",
      #                 "route53:ListResourceRecordSets",
      #                 "route53:GetHostedZone",
      #                 "route53:ChangeResourceRecordSets"
      #             ],
      #             "Resource": [
      #                 "*"
      #             ]
      #         }
      #     ]
      # }

      VCR.use_cassette("04-missing-getchange-permissions") do
        require_relative '../../testperms'
        client = SprinkleDNS::Route53Client.new(ACCESS_KEY_ID, SECRET_ACCESS_KEY)
        sdns   = SprinkleDNS::Client.new(client)

        sdns.entry('A', 'test.noaccess.billetto.com', '127.0.0.1', 3600, 'test.noaccess.billetto.com')
        sdns.entry('A', 'getchange.test.noaccess.billetto.com', '127.0.0.1', 3600, 'test.noaccess.billetto.com')
        sdns.entry('A', '1234.test.noaccess.billetto.com', '127.0.0.1', 3600, 'test.noaccess.billetto.com')
        sdns.sprinkle!

        pending
      end
    end

    it "should throw errors when no hosted zone is created at AWS" do
      VCR.use_cassette("05-missing-hosted-zone") do
        require_relative '../../testperms'
        client = SprinkleDNS::Route53Client.new(ACCESS_KEY_ID, SECRET_ACCESS_KEY)
        sdns   = SprinkleDNS::Client.new(client)

        sdns.entry('A', 'not_existing.billetto.com', '127.0.0.1', 3600, 'not_existing.billetto.com')
        sdns.sprinkle!

        pending
      end
    end

    it "should throw errors when there is a duplicate of hosted zones" do
      # Create two hosted zones with the name of: test.noaccess.billetto.com

      VCR.use_cassette("06-duplicate-hosted-zones") do
        require_relative '../../testperms'
        client = SprinkleDNS::Route53Client.new(ACCESS_KEY_ID, SECRET_ACCESS_KEY)
        sdns   = SprinkleDNS::Client.new(client)

        sdns.entry('A', 'test.noaccess.billetto.com', '127.0.0.1', 3600, 'test.noaccess.billetto.com')
        sdns.sprinkle!

        pending
      end
    end
  end
end
