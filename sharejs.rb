dep 'sharejs system', :app_user, :key, :env

dep 'sharejs env vars set', :domain

dep 'sharejs app', :env, :host, :domain, :app_user, :app_root, :key do
  requires [
    'user setup'.with(:key => key),

    "sharejs.systemd".with(app_user, env, app_root, "sharejs_#{env}")
  ]
end

dep 'sharejs packages' do
  requires [
    'postgres',
    'curl.lib',
    'running.nginx',
    'sharejs common packages'
  ]
end

dep 'sharejs dev' do
  requires [
    'sharejs common packages',
    'phantomjs' # for js testing
  ]
end

dep 'sharejs common packages' do
  requires [
    'bundler.gem',
    'postgres.bin',
    "coffeescript.bin"
  ]
end

dep 'sharejs.systemd', :username, :env, :app_root, :db_name do
  requires 'sharejs setup'.with(username, app_root, db_name)

  username.default!(shell('whoami'))
  db_name.default!("tc_#{env}")

  description "ShareJS server"
  command "/usr/bin/npm start"
  environment "NODE_ENV=#{env}"
  setuid username
  chdir "/srv/http/#{username}/current"
  respawn 'yes'

  met? {
    shell"curl -I localhost:9000/health"
  }
end

dep 'sharejs setup', :username, :app_root, :db_name do
  requires [
    'schema loaded'.with(:username => username, :root => app_root, :db_name => db_name),
    'npm packages installed'.with('~/current'),
    'rack.logrotate'.with(username),
  ]
end
