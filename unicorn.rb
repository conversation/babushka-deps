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
