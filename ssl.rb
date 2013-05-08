dep 'ssl cert in place', :nginx_prefix, :domain, :cert_name, :cert_source, :template => 'nginx' do
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

dep 'public key' do
  met? { '~/.ssh/id_dsa.pub'.p.grep(/^ssh-dss/) }
  meet { log shell("ssh-keygen -t dsa -f ~/.ssh/id_dsa -N ''") }
end
