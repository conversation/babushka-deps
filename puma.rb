dep 'puma.systemd', :env, :path, :username do
  description "Puma HTTP server"
  respawn 'yes'
  pid_file (path / 'tmp/pids/puma.pid').abs

  puma_path = (path / 'bin/puma').abs
  socket_path = (path / "tmp/sockets/puma.socket").abs
  command "#{puma_path} -b 'unix://#{socket_path}'"
  reload_command "/bin/kill -s USR1 $MAINPID" # reload workers

  setuid username
  chdir path.p.abs
  environment "APP_ENV=#{env}", "RACK_ENV=#{env}", "RAILS_ENV=#{env}", "LOG_TO_STDOUT=0", "LOG_TO_FILE=1"
end

dep 'log puma socket', :app_name, :path, :user  do
  requires [
    "script installed".with('socket-statsd-logger'),
    "puma-socket-statsd-logger.systemd".with(app_name, path, user)
  ]
end

dep 'puma-socket-statsd-logger.systemd', :app_name, :path, :user do
  socket_path = (path / "tmp/sockets/puma.socket").abs
  respawn 'yes'
  command "/usr/local/bin/socket-statsd-logger #{socket_path} #{app_name}.#{socket_path.basename}"
  setuid user
  chdir path.p.abs
end

dep 'log puma workers', :app_name, :path, :user  do
  requires [
    "script installed".with('puma-statsd-logger'),
    "puma-statsd-logger.systemd".with(app_name, path, user)
  ]
end

dep 'puma-statsd-logger.systemd', :app_name, :path, :user do
  respawn 'yes'
  command "/usr/local/bin/puma-statsd-logger #{path} #{app_name}.puma"
  setuid user
  chdir path.p.abs
end
