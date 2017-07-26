dep 'puma.systemd', :env, :path, :username, :threads, :workers do
  threads.default!('4')
  workers.default!('1')

  description "Puma HTTP server"
  respawn 'yes'
  pid_file (path / 'tmp/pids/puma.pid').abs

  puma_path = (path / 'bin/puma').abs
  socket_path = (path / "tmp/sockets/puma.socket").abs
  command "#{puma_path} -b 'unix://#{socket_path}' -t #{threads} -w #{workers}"
  reload_command "/bin/kill -s USR1 $MAINPID" # reload workers

  setuid username
  chdir path.p.abs
  environment "APP_ENV=#{env}", "RACK_ENV=#{env}", "RAILS_ENV=#{env}"
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
