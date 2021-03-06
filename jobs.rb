dep "jobs system", :app_user, :key, :env

dep "jobs env vars set", :domain

dep "jobs app", :env, :host, :domain, :app_user, :app_root, :key do
  requires "postgres extension".with(app_user, Util.database_name(app_root, env), "pg_trgm")

  requires [
    "user exists".with(username: app_user),

    "db".with(
      env: env,
      username: app_user,
      root: app_root,
      data_required: (env == "production" ? "yes" : "no")
    ),

    "delayed job".with(
      env: env,
      user: app_user
    ),

    "rails app".with(
      app_name: "jobs",
      env: env,
      domain: domain,
      username: app_user,
      path: app_root,
      enable_https: "yes"
    )
  ]
end

dep "jobs packages" do
  requires [
    "postgres",
    "curl.lib",
    "running.nginx",
    "jobs common packages"
  ]
end

dep "jobs dev" do
  requires "jobs common packages"
end

dep "jobs common packages" do
  requires [
    "bundler.gem",
    "postgres.bin",
    "postgresql-contrib.lib", # for pg_trgm, for search
    "libxml.lib", # for nokogiri
    "libxslt.lib", # for nokogiri
    "imagemagick.bin", # for paperclip
    "coffeescript.bin", # for barista
    "sasl.lib", # for memcached gem
    "tidy.bin" # for upmark
  ]
end
