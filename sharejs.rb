dep "sharejs system", :app_user, :key, :env

dep "sharejs env vars set", :domain

dep "sharejs app", :env, :host, :domain, :app_user, :app_root, :key do
  if env == 'production'
    domain.default!('sharejs.theconversation.com')
  else
    domain.default!('sharejs.tc-dev.net')
  end

  requires [
    "user exists".with(username: app_user),
    "sharejs.systemd".with(app_user, env, app_root, "sharejs_#{env}"),
    "proxy vhost enabled.nginx".with(
      app_name: "sharejs",
      domain: domain,
      proxy_port: "9000"
    )
  ]
end

dep "sharejs packages" do
  requires [
    "postgres",
    "curl.lib",
    "running.nginx",
    "sharejs common packages"
  ]
end

dep "sharejs dev" do
  requires [
    "sharejs common packages",
    "phantomjs" # for js testing
  ]
end

dep "sharejs common packages" do
  requires [
    "bundler.gem",
    "postgres.bin"
  ]
end

dep "sharejs.systemd", :username, :env, :app_root, :db_name do
  requires "sharejs setup".with(username, app_root, db_name)

  username.default!(shell("whoami"))
  db_name.default!("tc_#{env}")

  description "ShareJS server"
  command "/usr/bin/npm start"
  environment "NODE_ENV=#{env}", "PORT=9001"
  setuid username
  chdir "/srv/http/#{username}/current"
  respawn "yes"

  met? do
    shell "curl -I 127.0.0.1:9000/health"
  end
end

dep "sharejs setup", :username, :app_root, :db_name do
  requires [
    "schema loaded".with(username: username, root: app_root, db_name: db_name),
    "npm packages installed".with("~/current"),
    "rack.logrotate".with(username),
  ]
end
