dep 'unicorn upstart config', :env, :user do
  def app_root
    "/srv/http/#{user}/current"
  end

  def template_path
    dependency.load_path.parent / 'unicorn/unicorn.init.erb'
  end

  def service_name
    "#{user}_unicorn"
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
    running_count = shell('lsof -U').split("\n").grep(/#{Regexp.escape(app_root / 'tmp/sockets/unicorn.socket')}$/).count
    (running_count >= 3).tap {|result| # 1 master + 2 workers
      if result
        log_ok "This app has #{running_count} unicorn#{'s' unless running_count == 1} running (1 master + #{running_count - 1} workers)."
      elsif running_count > 0
        unmeetable! "This app is in an unexpected state: (1 master + #{running_count - 1} workers)."
      else
        log "This app has no unicorns running."
      end
    }
  end

  met? {
    if !(app_root / 'config/unicorn.rb').exists?
      log "Not starting any unicorns because there's no unicorn config."
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
