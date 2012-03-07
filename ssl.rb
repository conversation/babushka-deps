dep 'ssl certificate', :env, :domain, :root_domain do
  if env == 'production'
    if domain == root_domain
      requires 'ssl cert in place'.with(:domain => root_domain)
    else
      requires 'ssl cert in place'.with(:domain => "*.#{root_domain}")
    end
  else
    requires 'benhoskings:self signed cert.nginx'.with(
      :country => 'AU',
      :state => 'VIC',
      :city => 'Melbourne',
      :organisation => 'The Conversation',
      :domain => domain,
      :email => 'dev@theconversation.edu.au'
    )
  end
end

dep 'ssl cert in place', :nginx_prefix, :domain, :cert_source, :template => 'benhoskings:nginx' do
  nginx_prefix.default!('/opt/nginx')
  cert_source.default('~/current/config/certs')
  def names
    %w[key crt].map {|ext| "#{domain}.#{ext}" }
  end
  met? {
    names.all? {|name| (cert_path / name).exists? }
  }
  meet {
    sudo "mkdir -p #{cert_path}"
    names.each {|name| sudo "cp '#{cert_source / name}' #{cert_path.to_s.end_with('/')}" }
  }
end
