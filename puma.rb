dep 'puma.upstart', :env, :path, :username, :threads, :workers do
  threads.default!('4')
  workers.default!('1')

  respawn 'yes'
  command './bin/puma'
  setuid username
  chdir path.p.abs
  environment "RACK_ENV=#{env}", "RAILS_ENV=#{env}", "PUMA_THREADS=#{threads}", "PUMA_WORKERS=#{workers}"

  def config_current?
    if Babushka::Renderable.new(conf_dest).from?(template_path)
      true
    else
      log "upstart config needs updating"
      false
    end
  end

  def running?
    running_count = shell('lsof -U').split("\n").grep(/#{Regexp.escape(path / 'tmp/sockets/puma.socket')}$/).count
    if running_count > 0
      log_ok "There are #{running_count} puma processes running."
    else
      log "This app has no puma processes running."
    end
  end

  met? {
    if !(path / 'config/puma.rb').exists?
      log "Not starting any pumas because there's no puma config."
      true
    else
      config_current? && running?
    end
  }
end

dep 'log puma socket', :app_name, :path, :user  do
  requires [
    "script installed".with('socket-statsd-logger'),
    "puma-socket-statsd-logger.upstart".with(app_name, path, user)
  ]
end

dep 'puma-socket-statsd-logger.upstart', :app_name, :path, :user do
  socket_path = (path / "tmp/sockets/puma.socket").abs
  respawn 'yes'
  command "/usr/local/bin/socket-statsd-logger #{socket_path} #{app_name}.#{socket_path.basename}"
  setuid user
  chdir path.p.abs
  met? {
    shell?("ps aux | grep -v grep | grep 'socket-statsd-logger #{socket_path}'")
  }
end

