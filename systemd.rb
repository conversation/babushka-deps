meta :systemd do
  accepts_value_for :respawn, 'no' # Restart the process when it exits.
  accepts_value_for :description, "Unnamed service"
  accepts_value_for :pid_file
  accepts_value_for :command
  accepts_value_for :reload_command
  accepts_value_for :kill_signal
  accepts_list_for :environment
  accepts_value_for :chdir
  accepts_value_for :setuid
  accepts_value_for :suffix

  def service_name
    [setuid, basename, suffix]
      .compact
      .map { |token| token.to_s.gsub(/[ ,]/, "_") }
      .reject { |token| token.blank? }
      .join('_')
  end

  def conf_dest
    "/etc/systemd/system/#{service_name}.service"
  end

  def template_path
    dependency.load_path.parent / "systemd/service.erb"
  end

  def config_current?
    if Babushka::Renderable.new(conf_dest).from?(template_path)
      true
    else
      log "Systemd config needs updating"
      false
    end
  end

  template do
    meet do
      render_erb template_path, to: conf_dest, sudo: true
      sudo "systemctl start #{service_name}"
    end

    met? do
      config_current? && shell?("systemctl status #{service_name}")
    end
  end
end
