def postfix_conf
  "/etc/postfix/main.cf"
end

def restart_postfix
  if postfix_running?
    log_shell "restarting postfix", "/etc/init.d/postfix restart", :sudo => true
  end
end

def postfix_running?
  shell? "netstat -an | grep -E '^tcp.*[.:]25 +.*LISTEN'"
end

dep 'postfix.managed'

dep 'running.postfix' do

  requires 'configured.postfix'

  met? {
    postfix_running?.tap {|result|
      log "There is #{result ? 'something' : 'nothing'} listening on port 25."
    }
  }

  meet :on => :linux do
    sudo '/etc/init.d/postfix start'
  end
  meet :on => :osx do
    log_error "launchctl should have already started postfix. Check /var/log/system.log for errors."
  end
end

dep 'configured.postfix' do
  def hostname
    shell('hostname -f').chomp
  end

  requires 'postfix.managed'
  met? {
    Babushka::Renderable.new(postfix_conf).from?(dependency.load_path.parent / "postfix/main.cf.erb")
  }
  meet {
    render_erb 'postfix/main.cf.erb', :to => postfix_conf, :sudo => true
  }

  after { restart_postfix }
end
