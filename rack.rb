dep 'rack app', :app_name, :env, :domain, :username, :path, :listen_host, :listen_port, :enable_https, :proxy_host, :proxy_port, :nginx_prefix do
  username.default!(domain)
  path.default('~/current')
  env.default(ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'production')

  requires [
    'user exists'.with(username, '/srv/http'),
    'app bundled'.with(path, env),
    'vhost enabled.nginx'.with(app_name, env, domain, path, listen_host, listen_port, enable_https, proxy_host, proxy_port, nginx_prefix),
    'rack.logrotate'.with(username),
    'running.nginx',
    'unicorn.upstart'.with(env, username)
  ]
end
