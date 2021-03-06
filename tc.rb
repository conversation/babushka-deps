dep "tc system", :app_user, :key, :env do
  requires "throttling".with(env) # Temporarily ban misbehaving clients
end

dep "tc env vars set", :domain

dep "tc app", :env, :host, :domain, :app_user, :app_root, :key do
  requires [
    "postgres extension".with(app_user, Util.database_name(app_root, env), "unaccent"),
    "postgres extension".with(app_user, Util.database_name(app_root, env), "pg_trgm"),
    "postgres extension".with(app_user, Util.database_name(app_root, env), "fuzzystrmatch")
  ]

  requires [
    "user exists".with(username: app_user),

    "delayed job".with(
      env: env,
      user: app_user
    ),

    "delayed job".with(
      env: env,
      user: app_user,
      queue: "mailers"
    ),

    "delayed job".with(
      env: env,
      user: app_user,
      queue: "user_interface"
    ),

    "db".with(
      env: env,
      username: app_user,
      root: app_root,
      data_required: "yes"
    ),

    "postgres replication monitoring".with(test_user: app_user),

    "rails app".with(
      app_name: "tc",
      env: env,
      domain: domain,
      username: app_user,
      path: app_root,
      enable_https: "yes"
    )
  ]
end

dep "tc packages" do
  requires [
    "postgres",
    "postgresql-contrib.lib", # for unaccent, for search
    "running.postfix",
    "running.nginx",
    "tc common packages"
  ]
end

dep "tc dev" do
  requires [
    "tc common packages",
    "pv.bin", # for db:production:pull (and it's awesome anyway)
    "phantomjs", # for js testing
    "geoip database".with(app_root: "."),
    "submodules cloned",
    "npm packages installed".with("vendor/sharejs")
  ]
end

dep "submodules cloned" do
  met? do
    # Initalised and current submodules are listed with a leading ' '.
    shell("git submodule status").split("\n").all? {|l| l[/^ /] }
  end

  meet do
    shell("git submodule update --init")
  end
end

dep "tc common packages" do
  requires [
    "bundler.gem",
    "curl.lib",
    "postgres.bin",
    "geoip.bin", # for geoip-c
    "aspell dictionary.lib",
    "coffeescript.bin", # for barista
    "yarn.npm",
    "tidy.bin", # for upmark preprocessing in MarkdownController
    "imagemagick.bin", # for paperclip
    "pngquant.bin", # for reducing the size of PNGs
    "libxml.lib", # for nokogiri
    "libxslt.lib", # for nokogiri
    "libtag.lib" # for taglib-ruby gem
  ]
end
