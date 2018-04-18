meta :nginx do
  accepts_list_for :source

  def nginx_prefix
    "/etc/nginx".p
  end

  def nginx_conf
    nginx_prefix / "nginx.conf"
  end

  def vhost_conf
    nginx_prefix / "sites-available/#{domain}.conf"
  end

  def vhost_common
    nginx_prefix / "sites-available/#{domain}.common"
  end

  def vhost_link
    nginx_prefix / "sites-enabled/#{domain}.conf"
  end

  def upstream_name
    "#{domain}.upstream"
  end

  def cert_name
    # Grab the TLD from the domain (e.g. dw.theconversation.com ->
    # theconversation.com).
    cert_domain = domain.to_s
      .match(/([^.]+)\.([^.]+)$/).to_s
      .gsub('.', '_')

    "STAR_#{cert_domain}"
  end
end

dep "vhost enabled.nginx", :app_name, :env, :domain, :path, :enable_https do
  requires "vhost configured.nginx".with(app_name, env, domain, path, enable_https)

  met? { vhost_link.exists? }

  meet do
    sudo "ln -sf '#{vhost_conf}' '#{vhost_link}'"
  end

  after { Util.reload_service('nginx') }
end

dep "proxy vhost enabled.nginx", :app_name, :domain, :enable_https, :proxy_port do
  requires "proxy vhost configured.nginx".with(app_name, domain, enable_https, proxy_port)

  met? { vhost_link.exists? }

  meet do
    sudo "ln -sf '#{vhost_conf}' '#{vhost_link}'"
  end

  after { Util.reload_service('nginx') }
end

dep "vhost configured.nginx", :app_name, :env, :domain, :enable_https, :path do
  env.default!("production")
  enable_https.default!("yes")
  path.default("~#{domain}/current".p) if shell?("id", domain)

  def application_socket
    if has_unicorn_config?
      path / "tmp/sockets/unicorn.socket"
    elsif has_puma_config?
      path / "tmp/sockets/puma.socket"
    end
  end

  def has_unicorn_config?
    "#{path}/config/unicorn.rb".p.exists?
  end

  def has_puma_config?
    "#{path}/config/puma.rb".p.exists?
  end

  def up_to_date?(source_name, dest)
    source = dependency.load_path.parent / source_name
    if !source.p.exists?
      true # If the source config doesn't exist, this is optional (i.e. a .common conf).
    else
      Babushka::Renderable.new(dest).from?(source) && Babushka::Renderable.new(dest).clean?
    end
  end

  requires "configured.nginx"

  met? do
    up_to_date?("nginx/#{app_name}_vhost.conf.erb", vhost_conf) &&
    up_to_date?("nginx/#{app_name}_vhost.common.erb", vhost_common)
  end

  meet do
    render_erb "nginx/#{app_name}_vhost.conf.erb", to: vhost_conf, sudo: true
    render_erb "nginx/#{app_name}_vhost.common.erb", to: vhost_common, sudo: true if (dependency.load_path.parent / "nginx/#{app_name}_vhost.common.erb").p.exists?
  end
end

dep "proxy vhost configured.nginx", :app_name, :domain, :enable_https, :proxy_port do
  enable_https.default!("yes")

  def up_to_date?(source_name, dest)
    source = dependency.load_path.parent / source_name
    if !source.p.exists?
      true # If the source config doesn't exist, this is optional (i.e. a .common conf).
    else
      Babushka::Renderable.new(dest).from?(source) && Babushka::Renderable.new(dest).clean?
    end
  end

  requires "configured.nginx"

  met? do
    up_to_date?("nginx/#{app_name}_vhost.conf.erb", vhost_conf) &&
    up_to_date?("nginx/#{app_name}_vhost.common.erb", vhost_common)
  end

  meet do
    render_erb "nginx/#{app_name}_vhost.conf.erb", to: vhost_conf, sudo: true
    render_erb "nginx/#{app_name}_vhost.common.erb", to: vhost_common, sudo: true if (dependency.load_path.parent / "nginx/#{app_name}_vhost.common.erb").p.exists?
  end
end

dep "http basic logins.nginx", :domain, :username, :pass do
  met? { shell("curl -I -u #{username}:#{pass} #{domain}").val_for("HTTP/1.1")[/^[25]0\d\b/] }
  meet { (nginx_prefix / "conf/htpasswd").append("#{username}:#{pass.to_s.crypt(pass)}") }
  after { Util.reload_service('nginx') }
end

dep "running.nginx" do
  requires "configured.nginx"

  met? do
    Util.service_running?('nginx').tap do |result|
      log "There is #{result ? 'something' : 'nothing'} listening on port 80."
    end
  end

  meet { shell "systemctl start nginx" }
end

dep "configured.nginx" do
  requires "nginx.bin"

  met? do
    Babushka::Renderable.new(nginx_conf).from?(dependency.load_path.parent / "nginx/nginx.conf.erb")
  end

  meet do
    render_erb "nginx/nginx.conf.erb", to: nginx_conf, sudo: true
  end
end

dep "nginx.bin"
