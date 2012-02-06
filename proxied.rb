dep 'proxied app', :env, :app_name, :port do
  requires "#{app_name}".with(env, port)
  requires 'benhoskings:vhost enabled.nginx', {
    domain: "#{name}.#{server_name}",
    type: 'proxy',
    host: 'localhost',
    enable_ssl: 'no',
  }.merge(opts)
end

def proxied_app name, domain, opts
  creating_user "#{name}.#{domain}" do |username|
    babushka "conversation:#{name}"

    babushka 'benhoskings:vhost enabled.nginx', {
      domain: "#{name}.#{server_name}",
      type: 'proxy',
      host: 'localhost',
      enable_ssl: 'no',
    }.merge(opts)
  end
end
