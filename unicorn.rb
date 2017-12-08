dep "unicorn.systemd", :env, :path, :username do
  description "Unicorn HTTP server"
  respawn "yes"
  pid_file (path / "tmp/pids/unicorn.pid").abs

  command (path / "bin/unicorn -c config/unicorn.rb").abs
  reload_command "/bin/kill -s USR2 $MAINPID" # reload workers
  kill_signal "QUIT" # allow workers to finish their current request

  setuid username
  chdir path.p.abs
  environment "APP_ENV=#{env}", "RACK_ENV=#{env}", "RAILS_ENV=#{env}"
end

dep "log unicorn socket", :app_name, :path, :user do
  requires [
    "script installed".with("socket-statsd-logger"),
    "unicorn-socket-statsd-logger.systemd".with(app_name, path, user)
  ]
end

dep "unicorn-socket-statsd-logger.systemd", :app_name, :path, :user do
  socket_path = (path / "tmp/sockets/unicorn.socket").abs
  respawn "yes"
  command "/usr/local/bin/socket-statsd-logger #{socket_path} #{app_name}.#{socket_path.basename}"
  setuid user
  chdir path.p.abs
end
