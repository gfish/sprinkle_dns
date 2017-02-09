module SprinkleDNS
  class HostedZoneDomain
    def self.parse(domain)
      splitted = domain.split('.')

      if two_dotted_domain?(domain)
        [ splitted[-3], splitted[-2], splitted[-1] ].join('.') + '.'
      else
        [ splitted[-2], splitted[-1] ].join('.') + '.'
      end
    end

   private
    def self.two_dotted_domain?(domain)
      true if domain.include?('.co.uk')
    end
  end
end
