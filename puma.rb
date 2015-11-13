dep 'puma upstart config', :env, :user do
  def app_root
    "/srv/http/#{user}/current"
  end

  def template_path
    dependency.load_path.parent / 'puma/puma.init.erb'
  end

  def service_name
    "#{user}_puma"
  end

  def conf_dest
    "/etc/init/#{service_name}.conf"
  end

  def config_current?
    if Babushka::Renderable.new(conf_dest).from?(template_path)
      true
    else
      log "upstart config needs updating"
      false
    end
  end

  def running?
    running_count = shell('lsof -U').split("\n").grep(/#{Regexp.escape(app_root / 'tmp/sockets/puma.socket')}$/).count
    if running_count > 0
      log_ok "There are #{running_count} puma processes running."
    else
      log "This app has no puma processes running."
    end
  end

  met? {
    if !(app_root / 'config/puma.rb').exists?
      log "Not starting any pumas because there's no puma config."
      true
    else
      config_current? && running?
    end
  }
  meet {
    render_erb template_path, :to => conf_dest, :sudo => true
    sudo "initctl start #{service_name}; true"
    sleep 10
  }
end

