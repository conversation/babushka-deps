meta :upstart do
  accepts_value_for :task, 'no' # A fire-and-forget command; wait until it's exited.
  accepts_value_for :respawn, 'no' # Restart the process when it exits.
  accepts_value_for :command
  accepts_list_for :environment
  accepts_value_for :chdir
  accepts_value_for :setuid
  accepts_value_for :suffix
  accepts_value_for :start_delay, 5
  template {
    def conf_name
      [setuid, basename, suffix]
        .compact
        .map { |token| token.to_s.gsub(/[ ,]/, '_') }
        .reject { |token| token.blank? }
        .join('_')
    end
    def conf_dest
      "/etc/init/#{conf_name}.conf"
    end
    def template_path
      dependency.load_path.parent / "upstart/service.conf.erb"
    end
    meet {
      render_erb template_path, :to => conf_dest, :sudo => true
      sudo "initctl start #{conf_name}; true"
      sleep start_delay
    }
  }
end
