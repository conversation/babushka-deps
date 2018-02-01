dep "rails app", :app_name, :env, :domain, :username, :path, :enable_https do
  def has_webpack_config?
    (path / "webpack.config.js").exists?
  end

  if has_webpack_config?
    requires [
      "rack app".with(app_name, env, domain, username, path, enable_https),
      "webpack compile during deploy".with(env: env),
      "config ruby app server".with(app_name, path, env, username)
    ]
  else
    requires [
      "rack app".with(app_name, env, domain, username, path, enable_https),
      "common:assets precompiled".with(env: env, path: path),
      "config ruby app server".with(app_name, path, env, username)
    ]
  end
end

dep "sinatra app", :app_name, :env, :domain, :username, :path, :enable_https do
  requires [
    "rack app".with(app_name, env, domain, username, path, enable_https),
    "config ruby app server".with(app_name, path, env, username)
  ]
end

dep "rack app", :app_name, :env, :domain, :username, :path, :enable_https do
  username.default!(domain)
  path.default("~/current")
  env.default(ENV["RAILS_ENV"] || ENV["RACK_ENV"] || "production")

  requires [
    "user exists".with(username, "/srv/http"),
    "app bundled".with(path, env),
    "vhost enabled.nginx".with(app_name, env, domain, path, enable_https),
    "rack.logrotate".with(username),
    "running.nginx"
  ]
end

dep "config ruby app server", :app_name, :path, :env, :username do
  def has_unicorn_config?
    (path / "config/unicorn.rb").exists?
  end

  def has_puma_config?
    (path / "config/puma.rb").exists?
  end

  if has_unicorn_config?
    requires [
      "unicorn.systemd".with(env, path, username),
      "log unicorn socket".with(app_name, path, username)
    ]
  elsif has_puma_config?
    requires [
      "puma.systemd".with(env, path, username),
      "log puma socket".with(app_name, path, username),
      "log puma workers".with(app_name, path, username)
    ]
  end
end
