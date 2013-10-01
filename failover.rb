dep 'promote dallas to master' do
  requires [
    #'promote psql to master'.with(host: "prod-dal.tc-dev.net"),
    'update dns'.with(new_master_domain: 'prod-dal.tc-dev.net', new_standby_domain: 'prod-lon.tc-dev.net'),
  ]
end

dep 'promote london to master' do
  requires [
    'promote psql to master'.with(host: "prod-lon.tc-dev.net"),
    'update dns'.with(new_master_domain: 'prod-lon.tc-dev.net', new_standby_domain: 'prod-dal.tc-dev.net'),
  ]
end

dep 'promote psql to master', :host do
  met? {
    #shell('git submodule status').split("\n").all? {|l| l[/^ /] }
    false
  }
  meet {
    puts "promote psql to master (#{host})"
  }
end

dep 'update dns', :new_master_domain, :new_standby_domain, :api_username, :api_key do
  requires [
    "update dns record".with(prefix: "",             domain: "theconversation.com",    api_username: api_username, api_key: api_key, type: "ALIAS", value: "dot-com.#{new_master_domain}"),
    "update dns record".with(prefix: "www",          domain: "theconversation.com",    api_username: api_username, api_key: api_key, type: "CNAME", value: "dot-com.#{new_master_domain}"),
    "update dns record".with(prefix: "jobs",         domain: "theconversation.edu.au", api_username: api_username, api_key: api_key, type: "CNAME", value: "jobs.#{new_master_domain}"),
    "update dns record".with(prefix: "counter",      domain: "theconversation.edu.au", api_username: api_username, api_key: api_key, type: "CNAME", value: "counter.#{new_master_domain}"),
    "update dns record".with(prefix: "jobs",         domain: "theconversation.edu.au", api_username: api_username, api_key: api_key, type: "CNAME", value: "jobs.#{new_master_domain}"),
    "update dns record".with(prefix: "donate",       domain: "theconversation.edu.au", api_username: api_username, api_key: api_key, type: "CNAME", value: "donate.#{new_master_domain}"),
    "update dns record".with(prefix: "dw",           domain: "theconversation.edu.au", api_username: api_username, api_key: api_key, type: "CNAME", value: "dw.#{new_master_domain}"),
    "update dns record".with(prefix: "",             domain: "theconversation.edu.au", api_username: api_username, api_key: api_key, type: "ALIAS", value: "au-redirect.#{new_master_domain}"),
    "update dns record".with(prefix: "www",          domain: "theconversation.edu.au", api_username: api_username, api_key: api_key, type: "CNAME", value: "au-redirect.#{new_master_domain}"),
    "update dns record".with(prefix: "",             domain: "theconversation.org.uk", api_username: api_username, api_key: api_key, type: "ALIAS", value: "uk-redirect.#{new_master_domain}"),
    "update dns record".with(prefix: "www",          domain: "theconversation.org.uk", api_username: api_username, api_key: api_key, type: "CNAME", value: "uk-redirect.#{new_master_domain}"),
    "update dns record".with(prefix: "prod-master",  domain: "tc-dev.net",             api_username: api_username, api_key: api_key, type: "CNAME", value: new_master_domain),
    "update dns record".with(prefix: "prod-standby", domain: "tc-dev.net",             api_username: api_username, api_key: api_key, type: "CNAME", value: new_standby_domain),
  ]
end

dep 'update dns record', :prefix, :domain, :type, :value, :api_username, :api_key do
  setup {
    require 'dnsimple'
    DNSimple::Client.username  = api_username
    DNSimple::Client.api_token = api_key
  }

  def find_domain(string)
    remote_domain = DNSimple::Domain.find(domain)
    if remote_domain.nil?
      log_error("domain #{domain} not found")
    else
      remote_domain
    end
  end

  def find_record(domain, prefix, type)
    remote_domain = find_domain(domain)
    record = DNSimple::Record.all(remote_domain).detect { |record|
      record.name == prefix && record.record_type == type
    }
  end

  met? {
    record = find_record(domain, prefix, type)
    if record.nil?
      log("record #{prefix}.#{domain} #{type} not found")
      false
    else
      if record.content == value
        log_ok("record #{prefix}.#{domain} #{type} matches #{value}")
      else
        log "record #{prefix}.#{domain} #{type} is #{record.content}"
        false
      end
    end
  }

  meet {
    record = find_record(domain, prefix, type)
    if record.nil?
      log("creating #{prefix}.#{domain} #{type}")
      DNSimple::Record.create(remote_domain, prefix, type, value)
    else
      log("updating #{prefix}.#{domain} #{type} to #{value}")
      record.content = value
      record.save
    end
  }
end
