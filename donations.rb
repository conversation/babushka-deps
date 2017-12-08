dep "donations system", :app_user, :key, :env

dep "donations env vars set", :domain

dep "donations app", :env, :host, :domain, :app_user, :app_root, :key do
  requires [
    "ssl cert in place".with(domain: domain, env: env)
  ]

  requires [
    "db".with(
      env: env,
      username: app_user,
      root: app_root,
      data_required: "no"
    ),

    "delayed job".with(
      env: env,
      user: app_user
    ),

    "rails app".with(
      app_name: "donate",
      env: env,
      domain: domain,
      username: app_user,
      path: app_root
    )
  ]
end

dep "donations packages" do
  requires [
    "postgres",
    "running.postfix",
    "running.nginx",
    "donations common packages"
  ]
end

dep "donations dev" do
  requires "donations common packages"
end

dep "donations common packages" do
  requires [
    "bundler.gem",
    "postgres.bin",
    "libxml.lib", # for nokogiri
    "libxslt.lib", # for nokogiri
    "coffeescript.bin" # for barista
  ]
end
