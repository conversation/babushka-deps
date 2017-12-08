meta :postfix do
  def postfix_conf
    "/etc/postfix/main.cf"
  end

  def sasl_passwd
    "/etc/postfix/sasl_passwd"
  end

  def start_postfix
    log_shell "Starting postfix...", "systemctl start postfix"
  end

  def restart_postfix
    if postfix_running?
      log_shell "Restarting postfix...", "systemctl restart postfix"
    end
  end

  def postfix_running?
    shell? "systemctl is-active postfix"
  end
end

dep "postfix.bin"
dep "mailutils.bin"

dep "running.postfix" do
  requires "configured.postfix"

  met? do
    postfix_running?.tap do |result|
      log "There is #{result ? 'something' : 'nothing'} listening on port 25."
    end
  end

  meet on: :linux do
    start_postfix
  end
  meet on: :osx do
    log_error "launchctl should have already started postfix. Check /var/log/system.log for errors."
  end
end

dep "configured.postfix", :mailgun_password do
  def hostname
    shell("hostname -f").chomp
  end

  requires "postfix.bin"
  requires "mailutils.bin"

  met? do
    Babushka::Renderable.new(postfix_conf).from?(dependency.load_path.parent / "postfix/main.cf.erb")
    Babushka::Renderable.new(sasl_passwd).from?(dependency.load_path.parent / "postfix/sasl_passwd.erb")
  end

  meet do
    render_erb "postfix/main.cf.erb", to: postfix_conf
    render_erb "postfix/sasl_passwd.erb", to: sasl_passwd
    shell "chmod 600 /etc/postfix/sasl_passwd"
    shell "postmap /etc/postfix/sasl_passwd"
  end

  after { restart_postfix }
end
