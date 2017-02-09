require 'spec_helper'

RSpec.describe SprinkleDNS::Client do
  it 'as' do
    r53c = SprinkleDNS::Route53Client.new('1','2')
    sdns = SprinkleDNS::Client.new(r53c)

    sdns.entry('A',     'kaspergrubbe.com',             '88.80.80.80', 60)
    sdns.entry('A',     'assets.kaspergrubbe.com',      '88.80.80.80', 60)
    sdns.entry('MX',    'mail.kaspergrubbe.com',        ['10 mailserver.example.com', '20 mailserver2.example.com'], 300)
    sdns.entry('MX',    'main.kaspergrubbe.com',        ['10 mailserver.example.com'], 300)
    sdns.entry('A',     'streamy.kaspergrubbe.com.',    '198.211.96.200', 60)
    sdns.entry('A',     'blog.kaspergrubbe.com',        '198.211.96.200', 60)
    sdns.entry('CNAME', 'www.es.kaspergrubbe.com',      "#{Time.now.to_i}.example.com.", 42, 'es.kaspergrubbe.com')
    sdns.entry('CNAME', 'staging.es.kaspergrubbe.com.', "#{Time.now.to_i}.example.com.", 42, 'es.kaspergrubbe.com.')

    # TODO verify the entries
  end

end
