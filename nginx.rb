dep 'vhost enabled', :app_name, :domain, :domain_aliases, :path, :listen_host, :listen_port, :proxy_host, :proxy_port, :nginx_prefix, :enable_http, :enable_https, :force_https, :template => 'benhoskings:nginx' do
  requires 'vhost configured'.with(app_name, domain, domain_aliases, path, listen_host, listen_port, proxy_host, proxy_port, nginx_prefix, enable_http, enable_https, force_https)
  met? { vhost_link.exists? }
  meet {
    sudo "mkdir -p #{nginx_prefix / 'conf/vhosts/on'}"
    sudo "ln -sf '#{vhost_conf}' '#{vhost_link}'"
  }
  after { restart_nginx }
end

dep 'vhost configured', :app_name, :env, :domain, :domain_aliases, :path, :listen_host, :listen_port, :proxy_host, :proxy_port, :nginx_prefix, :enable_http, :enable_https, :force_https, :template => 'benhoskings:nginx' do
  env.default!('production')
  domain_aliases.default('').ask('Domains to alias (no need to specify www. aliases)')
  listen_host.default!('[::]')
  listen_port.default!('80')
  proxy_host.default('localhost')
  proxy_port.default('8000')
  enable_http.default!('yes')
  enable_https.default('no')
  force_https.default('no')
  def www_aliases
    "#{domain} #{domain_aliases}".split(/\s+/).reject {|d|
      d[/^\*\./] || d[/^www\./]
    }.map {|d|
      "www.#{d}"
    }
  end
  def server_names
    [domain].concat(
      domain_aliases.to_s.split(/\s+/)
    ).concat(
      www_aliases
    ).uniq
  end

  path.default("~#{domain}/current".p) if shell?('id', domain)
  nginx_prefix.default!('/opt/nginx')

  requires 'benhoskings:configured.nginx'.with(nginx_prefix)
  requires 'benhoskings:unicorn configured'.with(path)

  met? {
    Babushka::Renderable.new(vhost_conf).from?(dependency.load_path.parent / "nginx/#{app_name}_vhost.conf.erb")
  }
  meet {
    sudo "mkdir -p #{nginx_prefix / 'conf/vhosts'}"
    render_erb "nginx/#{app_name}_vhost.conf.erb", :to => vhost_conf, :sudo => true
  }
end

dep 'http basic logins.nginx', :nginx_prefix, :domain, :username, :pass do
  nginx_prefix.default!('/opt/nginx')
  requires 'http basic auth enabled.nginx'.with(nginx_prefix, domain)
  met? { shell("curl -I -u #{username}:#{pass} #{domain}").val_for('HTTP/1.1')[/^[25]0\d\b/] }
  meet { append_to_file "#{username}:#{pass.to_s.crypt(pass)}", (nginx_prefix / 'conf/htpasswd'), :sudo => true }
  after { restart_nginx }
end

dep 'http basic auth enabled.nginx', :nginx_prefix, :domain do
  requires 'configured.nginx'.with(nginx_prefix)
  met? { shell("curl -I #{domain}").val_for('HTTP/1.1')[/^401\b/] }
  meet {
    append_to_file %Q{auth_basic 'Restricted';\nauth_basic_user_file htpasswd;}, vhost_common, :sudo => true
  }
  after {
    sudo "touch #{nginx_prefix / 'conf/htpasswd'}"
    restart_nginx
  }
end