dep 'mobwrite' do
  requires [
    'mobwrite daemon.supervisor',
    'mobwrite gateway.supervisor'
  ]
end

meta :supervisor do
  accepts_value_for :command
  accepts_value_for :directory
  accepts_value_for :user
  template {
    def conf_name
      name.gsub(' ', '_')
    end
    def conf_dest
      "/etc/supervisor/conf.d/#{conf_name}.conf"
    end
    meet {
      render_erb "supervisor/daemon.conf", :to => conf_dest, :sudo => true
    }
    after {
      sudo 'kill -HUP `cat /var/run/supervisord.pid`'
      sleep 2
    }
  }
end

dep 'mobwrite daemon.supervisor' do
  command "python mobwrite_daemon.py"
  directory "/srv/http/mobwrite/current/daemon"
  user "mobwrite.theconversation.edu.au"
  met? {
    !shell("ps aux").split("\n").grep(command).empty?
  }
end

dep 'mobwrite gateway.supervisor' do
  requires 'gunicorn', ''
  command "gunicorn gateway:application"
  directory "/srv/http/mobwrite/current/daemon"
  user "mobwrite.theconversation.edu.au"
  met? {
    (shell("curl -I localhost:8000") || '').val_for('Server')['gunicorn']
  }
end
