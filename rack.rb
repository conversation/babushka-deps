dep 'rack app', :app_name, :domain, :username, :path, :listen_host, :listen_port, :enable_https, :proxy_host, :proxy_port, :env, :nginx_prefix, :data_required do
  username.default!(shell('whoami'))
  path.default('~/current')
  env.default(ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'production')

  requires 'webapp'.with(app_name, env, domain, username, path, listen_host, listen_port, enable_https, proxy_host, proxy_port, nginx_prefix)
  requires 'benhoskings:web repo'.with(path)
  requires 'app bundled'.with(path, env)
  requires 'rack.logrotate'.with(username)
end

dep 'webapp', :app_name, :env, :domain, :username, :path, :listen_host, :listen_port, :enable_https, :proxy_host, :proxy_port, :nginx_prefix do
  username.default!(domain)
  requires [
    'user exists'.with(username, '/srv/http'),
    'vhost enabled.nginx'.with(app_name, env, domain, path, listen_host, listen_port, enable_https, proxy_host, proxy_port, nginx_prefix),
    'running.nginx',
    'unicorn.upstart'.with(env, username)
  ]
end
