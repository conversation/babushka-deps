meta :supervisor do
  accepts_value_for :command
  accepts_value_for :directory
  accepts_value_for :user
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
    }
    after {
      sudo 'kill -HUP `cat /var/run/supervisord.pid`'
      sleep 5
    }
  }
end
