def zonify!(domain)
  domain = "#{domain}." unless domain.end_with?('.')
  domain
end
