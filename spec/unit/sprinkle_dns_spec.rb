require 'spec_helper'

RSpec.describe SprinkleDNS::Client do
  it "as" do
    s = SprinkleDNS::Client.new(1,2)

    s.entry("A",  'kaspergrubbe.com',        '88.80.80.80', 60)
    s.entry("A",  'assets.kaspergrubbe.com', '88.80.80.80', 60)
    s.entry("MX", 'mail.kaspergrubbe.com',   ['10 mailserver.example.com', '20 mailserver2.example.com'], 300)
    s.entry("MX", 'main.kaspergrubbe.com',   ['10 mailserver.example.com'], 300)
    s.entry("A",  'streamy.kaspergrubbe.com.', '198.211.96.200', 60)

    # TODO verify the entries
  end

end
