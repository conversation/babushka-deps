dep 'ssl certificate', :env, :domain do
  if env == 'production'
    requires 'ssl cert in place'.with(domain: domain)
  else
    requires 'benhoskings:self signed cert.nginx'.with(
      country: 'AU',
      state: 'VIC',
      city: 'Melbourne',
      organisation: 'The Conversation',
      domain: domain,
      email: 'dev@theconversation.edu.au'
    )
  end
end

dep 'ssl cert in place', :nginx_prefix, :domain, :cert_source, :template => 'benhoskings:nginx' do
  nginx_prefix.default('/opt/nginx')
  cert_source.default('~/current/config/dollhouse/assets/certs')
  def names
    %w[key crt].map {|ext| "#{domain}.#{ext}" }
  end
  met? {
    names.all? {|name| (cert_path / name).exists? }
  }
  before {
    sudo "mkdir -p #{cert_path}"
  }
  meet {
    names.each {|name| sudo "cp '#{cert_source / name}' #{cert_path.to_s.end_with('/')}" }
  }
end
