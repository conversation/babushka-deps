dep "proxied app", :env, :app_name, :domain, :port do
  requires "#{app_name}".with(env)
  requires "vhost enabled.nginx".with(
    domain: domain,
    type: "proxy",
    proxy_host: "localhost",
    proxy_port: port
  )
end
