# represents a company that terminates end user HTTP requests in edge data
# centres and then proxies the request back to our application server.
#
# At this stage we're using fastly, but we could switch to a competitor like
# cloudflare if needed.
#
class ProxyService
  # Create a new ProxyService instance that can be queried or used to initiate
  # config changes.
  #
  # * api_key is the API key assigned to our account
  # * service_name is the name of the site to interact with. Probable tc, dw,
  #   jobs, etc.
  #
  def initialize(api_key, service_name)
    @fastly = Fastly.new(:api_key => api_key)
    @service = @fastly.list_services.detect { |service|
      service.name == service_name
    }
    @backend_name = "prod-master"
    raise ArgumentError, "service #{service_name} not found" unless @service
  end

  # returns the current backend address for this service. This should be a string
  # containing a hostname or IP address. For now it's assumed there is only a
  # single backend address for each service.
  #
  def backend_address
    current_version = @service.version
    get_backend(current_version).address
  end

  # update the address of this service's backend server. This should be done when
  # we're failing over to the standby server. For now it's assumed there is only
  # a single backend address for each service.
  #
  def update_backend_address(new_address)
    current_version = @service.version

    if get_backend(current_version).address != new_address
      new_version = current_version.clone
      new_backend = get_backend(new_version)
      new_backend.address = new_address
      new_backend.save!
      new_version.activate!
    else
      true
    end
  end

  private

  def get_backend(version)
    backend = @fastly.list_backends(:service_id => @service.id, :version => version.number).detect { |b|
      b.name == @backend_name
    }
    raise "backend #{backend_name} not found" if backend.nil?
    backend
  end

end

dep 'promote staging-a to master' do
  requires [
    'promote psql to master'.with(:host => "staging-a.tc-dev.net"),
    'update staging dns'.with(:new_master_domain => 'staging-a.tc-dev.net', :new_standby_domain => 'staging-b.tc-dev.net'),
  ]
end

dep 'promote staging-b to master' do
  requires [
    'promote psql to master'.with(:host => "staging-b.tc-dev.net"),
    'update staging dns'.with(:new_master_domain => 'staging-b.tc-dev.net', :new_standby_domain => 'staging-a.tc-dev.net'),
  ]
end

dep 'promote dallas to master' do
  requires [
    'promote psql to master'.with(:host => "prod-dal.tc-dev.net"),
    'update prod dns'.with(:new_master_domain => 'prod-dal.tc-dev.net', :new_standby_domain => 'prod-lon.tc-dev.net'),
  ]
end

dep 'promote london to master' do
  requires [
    'promote psql to master'.with(:host => "prod-lon.tc-dev.net"),
    'update prod dns'.with(:new_master_domain => 'prod-lon.tc-dev.net', :new_standby_domain => 'prod-dal.tc-dev.net'),
    'update fastly'.with(:new_master_domain => 'prod-lon.tc-dev.net'),
  ]
end

dep 'promote psql to master', :host do
  met? {
    # this command will return 'f' for master postgres clusters and 't'
    # for standby clusters
    result = shell(%Q{ssh postgres@#{host} "psql postgres -t -c 'SELECT pg_is_in_recovery()'"}).strip
    result == "f"
  }
  meet {
    confirm "OK to promote psql on #{host} to master. There's no going back!" do
      shell(%Q{ssh postgres@#{host} "touch /var/lib/postgresql/9.2/main/trigger"})
    end
  }
end

dep 'update staging dns', :new_master_domain, :new_standby_domain, :api_username, :api_key do
  requires [
    "update dns record".with(:prefix => "staging",             :domain => "tc-dev.net",    :api_username => api_username, :api_key => api_key, :type => "CNAME", :value => new_master_domain),
    "update dns record".with(:prefix => "staging-standby",     :domain => "tc-dev.net",    :api_username => api_username, :api_key => api_key, :type => "CNAME", :value => new_standby_domain),
  ]
end

dep 'update prod dns', :new_master_domain, :new_standby_domain, :api_username, :api_key do
  requires [
    "update dns record".with(:prefix => "",             :domain => "theconversation.com",    :api_username => api_username, :api_key => api_key, :type => "ALIAS", :value => "dot-com.#{new_master_domain}"),
    "update dns record".with(:prefix => "www",          :domain => "theconversation.com",    :api_username => api_username, :api_key => api_key, :type => "CNAME", :value => "dot-com.#{new_master_domain}"),
    "update dns record".with(:prefix => "jobs",         :domain => "theconversation.edu.au", :api_username => api_username, :api_key => api_key, :type => "CNAME", :value => "jobs.#{new_master_domain}"),
    "update dns record".with(:prefix => "counter",      :domain => "theconversation.edu.au", :api_username => api_username, :api_key => api_key, :type => "CNAME", :value => "counter.#{new_master_domain}"),
    "update dns record".with(:prefix => "jobs",         :domain => "theconversation.edu.au", :api_username => api_username, :api_key => api_key, :type => "CNAME", :value => "jobs.#{new_master_domain}"),
    "update dns record".with(:prefix => "jobs",         :domain => "theconversation.com",    :api_username => api_username, :api_key => api_key, :type => "CNAME", :value => "jobs.#{new_master_domain}"),
    "update dns record".with(:prefix => "donate",       :domain => "theconversation.edu.au", :api_username => api_username, :api_key => api_key, :type => "CNAME", :value => "donate.#{new_master_domain}"),
    "update dns record".with(:prefix => "",             :domain => "theconversation.edu.au", :api_username => api_username, :api_key => api_key, :type => "ALIAS", :value => "au-redirect.#{new_master_domain}"),
    "update dns record".with(:prefix => "www",          :domain => "theconversation.edu.au", :api_username => api_username, :api_key => api_key, :type => "CNAME", :value => "au-redirect.#{new_master_domain}"),
    "update dns record".with(:prefix => "",             :domain => "theconversation.org.uk", :api_username => api_username, :api_key => api_key, :type => "ALIAS", :value => "uk-redirect.#{new_master_domain}"),
    "update dns record".with(:prefix => "www",          :domain => "theconversation.org.uk", :api_username => api_username, :api_key => api_key, :type => "CNAME", :value => "uk-redirect.#{new_master_domain}"),
    "update dns record".with(:prefix => "prod-master",  :domain => "tc-dev.net",             :api_username => api_username, :api_key => api_key, :type => "CNAME", :value => new_master_domain),
    "update dns record".with(:prefix => "prod-standby", :domain => "tc-dev.net",             :api_username => api_username, :api_key => api_key, :type => "CNAME", :value => new_standby_domain),
  ]
end

dep 'update fastly', :new_master_domain, :fastly_api_key do
  requires [
    "update fastly backend".with(:service => "dw", :backend_address => "dw.#{new_master_domain}", :fastly_api_key => fastly_api_key)
  ]
end

dep 'update fastly backend', :service, :backend_address, :fastly_api_key do
  def proxy
    ProxyService.new(fastly_api_key, service)
  end

  setup {
    require 'fastly'
  }
  met? {
    log("checking if current backend address is #{backend_address}")
    proxy.backend_address == backend_address
  }
  meet {
    log("updating backend address to #{backend_address}")
    proxy.update_backend_address(backend_address)
  }
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
      DNSimple::Record.create(remote_domain, prefix, type, value, :ttl => 60)
    else
      log("updating #{prefix}.#{domain} #{type} to #{value}")
      record.content = value
      record.ttl = 60
      record.save
    end
  }
end
