dep 'proxied app', :env, :app_name, :domain, :port do
  requires "#{app_name}".with(env)
  requires 'benhoskings:vhost enabled.nginx'.with(
    domain: domain,
    type: 'proxy',
    host: 'localhost',
    enable_ssl: 'no',
  )
end
