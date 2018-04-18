dep "analytics system", :app_user, :key, :env

dep "analytics env vars set", :domain

dep "analytics app", :env, :host, :domain, :app_user, :app_root, :key do
  requires [
    "user exists".with(username: app_user),

    "db".with(
      env: env,
      username: app_user,
      root: app_root,
      data_required: "no"
    ),

    "rails app".with(
      app_name: "analytics",
      env: env,
      domain: domain,
      username: app_user,
      path: app_root
    )
  ]
end

dep "analytics packages" do
  requires [
    "postgres",
    "running.nginx",
    "analytics common packages"
  ]
end

dep "analytics dev" do
  requires "analytics common packages"
end

dep "analytics common packages" do
  requires [
    "bundler.gem",
    "libxml.lib", # for nokogiri
    "libxslt.lib", # for nokogiri
    "sasl.lib", # for memcached gem
    "coffeescript.bin" # for barista
  ]
end
