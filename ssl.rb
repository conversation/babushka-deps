dep 'ssl certificate', :env, :domain, :cert_name do
  if env == 'production'
    requires 'ssl cert in place'.with(:domain => domain, :cert_name => cert_name)
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

dep 'ssl cert in place', :nginx_prefix, :domain, :cert_name, :cert_source, :template => 'benhoskings:nginx' do
  nginx_prefix.default!('/opt/nginx')
  cert_source.default('~/current/config/certs')
  met? {
    %w[key crt].all? {|ext| (cert_path / "#{domain}.#{ext}").exists? }
  }
  meet {
    sudo "mkdir -p #{cert_path}"
    %w[key crt].all? {|ext| sudo "cp '#{cert_source / cert_name}.#{ext}' '#{cert_path / domain}.#{ext}'" }
    sudo "chmod 600 '#{cert_path / domain}'.*"
    restart_nginx
  }
end
