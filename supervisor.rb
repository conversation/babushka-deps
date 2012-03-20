meta :supervisor do
  accepts_value_for :restart, 'default'
  accepts_value_for :command
  accepts_list_for :environment
  accepts_value_for :directory
  accepts_value_for :user
  accepts_value_for :start_delay, 5
  template {
    def conf_name
      basename.gsub(' ', '_')
    end
    def conf_dest
      "/etc/supervisor/conf.d/#{conf_name}.conf"
    end
    requires 'supervisor.managed'
    meet {
      render_erb "supervisor/daemon.conf", :to => conf_dest, :sudo => true
      sudo "supervisorctl reread"
      sudo "supervisorctl start #{conf_name}"
      sleep start_delay
    }
  }
end
