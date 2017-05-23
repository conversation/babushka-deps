dep 'rails app', :app_name, :env, :domain, :username, :path, :listen_host, :listen_port, :enable_https, :proxy_host, :proxy_port, :threads, :workers do
  requires [
    'rack app'.with(app_name, env, domain, username, path, listen_host, listen_port, enable_https, proxy_host, proxy_port),
    'config ruby app server'.with(app_name, path, env, username, threads, workers)
  ]
end

dep 'sinatra app', :app_name, :env, :domain, :username, :path, :listen_host, :listen_port, :enable_https, :proxy_host, :proxy_port, :threads, :workers do
  requires [
    'rack app'.with(app_name, env, domain, username, path, listen_host, listen_port, enable_https, proxy_host, proxy_port),
    'config ruby app server'.with(app_name, path, env, username, threads, workers)
  ]
end

dep 'rack app', :app_name, :env, :domain, :username, :path, :listen_host, :listen_port, :enable_https, :proxy_host, :proxy_port do
  username.default!(domain)
  path.default('~/current')
  env.default(ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'production')

  requires [
    'user exists'.with(username, '/srv/http'),
    'common:app bundled'.with(path, env),
    'vhost enabled.nginx'.with(app_name, env, domain, path, listen_host, listen_port, enable_https, proxy_host, proxy_port),
    'rack.logrotate'.with(username),
    'running.nginx'
  ]
end

dep 'config ruby app server', :app_name, :path, :env, :username, :threads, :workers do
  def has_unicorn_config?
    (path / "config/unicorn.rb").exists?
  end

  def has_puma_config?
    (path / "config/puma.rb").exists?
  end

  if has_unicorn_config?
    requires [
      'unicorn.systemd'.with(env, path, username, threads, workers),
      'log unicorn socket'.with(app_name, path, username)
    ]
  elsif has_puma_config?
    requires [
      'puma.systemd'.with(env, path, username, threads, workers),
      'log puma socket'.with(app_name, path, username)
    ]
  end
end
