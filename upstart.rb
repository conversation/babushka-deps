meta :upstart do
  accepts_value_for :respawn
  accepts_value_for :command
  accepts_list_for :environment
  accepts_value_for :chdir
  accepts_value_for :setuid
  accepts_value_for :start_delay, 5
  template {
    def conf_name
      "#{user}_#{basename.gsub(' ', '_')}"
    end
    def conf_dest
      "/etc/init/#{conf_name}.conf"
    end
    meet {
      render_erb "upstart/service.conf", :to => conf_dest, :sudo => true
      sudo "initctl start #{conf_name}"
      sleep start_delay
    }
  }
end
