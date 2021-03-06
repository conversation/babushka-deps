dep "puma.systemd", :env, :path, :username do
  description "Puma HTTP server"
  respawn "yes"
  pid_file (path / "tmp/pids/puma.pid").abs

  puma_path = (path / "bin/puma").abs
  socket_path = (path / "tmp/sockets/puma.socket").abs
  command "#{puma_path} -b 'unix://#{socket_path}'"
  reload_command "/bin/kill -s USR1 $MAINPID" # reload workers

  setuid username
  chdir path.p.abs
  environment "APP_ENV=#{env}", "RACK_ENV=#{env}", "RAILS_ENV=#{env}", "LOG_TO_STDOUT=0", "LOG_TO_FILE=1"
end
