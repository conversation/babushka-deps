
# Several deps load YAML, e.g. database configs.
require "yaml"

dep "no known_hosts conflicts", :host do
  met? do
    "~/.ssh/known_hosts".p.grep(/\b#{Regexp.escape(host)}\b/).blank?.tap do |result|
      log_ok "#{host} doesn't appear in #{'~/.ssh/known_hosts'.p}." if result
    end
  end

  meet do
    shell "sed -i '' -e '/#{Regexp.escape(host)}/d' ~/.ssh/known_hosts"
  end
end

dep "public key in place", :host, :keys do
  requires_when_unmet "no known_hosts conflicts".with(host)

  met? do
    shell?("ssh -o PasswordAuthentication=no root@#{host} 'true'").tap do |result|
      log "root@#{host} is#{"n't" unless result} accessible via publickey auth.", as: (:ok if result)
    end
  end

  meet do
    shell "ssh root@#{host} 'mkdir -p ~/.ssh; cat > ~/.ssh/authorized_keys'", input: keys
  end
end

dep "babushka bootstrapped", :host do
  met? do
    raw_shell("ssh root@#{host} 'babushka --version'").stdout[/[\d\.]{5,} \([0-9a-f]{7,}\)/].tap do |result|
      log_ok "#{host} is running babushka-#{result}." if result
    end
  end

  meet do
    shell %{ssh root@#{host} 'sh -'}, input: shell("curl https://babushka.me/up"), log: true
  end
end

meta :remote do
  def as(user)
    previous_user, @user = @user, user
    yield
  ensure
    @user = previous_user
  end

  def host_spec
    "#{@user || 'root'}@#{host}"
  end

  def remote_shell(*cmd)
    opening_message = [
      host_spec.colorize("on grey"), # user@host spec
      cmd.map {|i| i.sub(/^(.{50})(.{3}).*/m, '\1...') }.join(" ") # the command, with long args truncated
    ].join(" $ ")
    log opening_message, closing_status: opening_message do
      shell "ssh", "-o", "PermitLocalCommand=no", "-A", host_spec, cmd.map{|i| "'#{i}'" }.join(" "), log: true
    end
  end

  def remote_babushka(dep_spec, args = {})
    remote_args = [
      "--defaults",
      ("--update" if Babushka::Base.task.opt(:update)),
      ("--debug"  if Babushka::Base.task.opt(:debug)),
      ("--colour" if $stdin.tty?),
      "--show-args"
    ].compact

    remote_args.concat args.keys.map {|k| "#{k}=#{args[k]}" }

    remote_shell(
      "babushka",
      dep_spec,
      *remote_args
    ).tap do |result|
      unmeetable! "The remote babushka reported an error." unless result
    end
  end

  def failable_remote_babushka(dep_spec, args = {})
    remote_babushka(dep_spec, args)
  rescue Babushka::UnmeetableDep
    log "That remote run was marked as failable; moving on."
    false
  end
end

# This dep couples two concerns together (kernel & apt upgrade) and should be refactored.
dep "host updated", :host, template: "remote" do
  def reboot_remote!
    remote_shell("reboot")

    log "Waiting for #{host} to go offline...", newline: false
    while shell?("ssh", "-o", "ConnectTimeout=1", host_spec, "true")
      print "."
      sleep 5
    end
    puts " gone."

    log "Waiting for #{host} to boot...", newline: false
    until shell?("ssh", "-o", "ConnectTimeout=1", host_spec, "true")
      print "."
      sleep 5
    end
    puts " booted."
  end

  met? do
    # Make sure we're running on the correct kernel (it should have been installed and booted
    # by the above upgrade; this dep won't attempt an install).
    remote_babushka "conversation:kernel running", version: "3.2.0-43-generic" # linux-3.2.0-43.68, for the CVE-2013-2094 fix.
  end

  meet do
    # First we need to configure apt. This involves a dist-upgrade, which should update the kernel.
    remote_babushka "conversation:apt configured"
    # The above update could have touched the kernel and/or glibc, so a reboot might be required.
    reboot_remote!
  end
end

# This is massive and needs a refactor, but it works for now.
dep "host provisioned", :host, :host_name, :ref, :env, :app_name, :app_user, :domain, :app_root, :keys, :check_path, :expected_content_path, :expected_content, :mailgun_password, template: "remote" do
  # In production, default the domain to the app user (specified per-app).
  domain.default!(app_user) if env == "production"

  keys.default!((dependency.load_path.parent / "config/authorized_keys").read)
  app_root.default!("~/current")
  check_path.default!("/health")

  def curl_command
    "curl -v -L --connect-timeout 5 --max-time 30 --resolve #{domain}:80:#{host} --resolve #{domain}:443:#{host}"
  end

  def check_host
    cmd = raw_shell("#{curl_command} http://#{domain}#{check_path}")

    if !cmd.ok?
      log "Couldn't connect to http://#{host}."
      :down
    else
      log_ok "#{host} is up."

      if cmd.stderr.val_for("Status") != "200 OK"
        log_warn "#{domain}#{check_path} on #{host} reported a problem:\n#{cmd.stdout}"
        :non_200
      else
        log_ok "#{domain}#{check_path} on #{host} responded with 200 OK."

        check_expected_content ? :ok : :expected_content_missing
      end
    end
  end

  def check_expected_content
    if !expected_content_path.set?
      true # Nothing to check.
    else
      check_output = shell("#{curl_command} http://#{domain}#{expected_content_path} | grep -c '#{expected_content}'")

      (check_output.to_i > 0).tap do |result|
        if result
          log_ok "#{domain}#{expected_content_path} on #{host} contains '#{expected_content}'."
        else
          log_warn "#{domain}#{expected_content_path} on #{host} doesn't contain '#{expected_content}'."
        end
      end
    end
  end

  met? do
    case check_host
    when :down
      false
    when :non_200, :expected_content_missing
      @confirm_beforehand = true
      false
    when :ok
      @run || log_warn("The app seems to be up; babushkaing anyway. (How bad could it be?)")
    end
  end

  prepare do
    unmeetable! "OK, bailing." if @confirm_beforehand && !confirm("Sure you want to provision #{domain} on #{host}?")
  end

  requires_when_unmet "public key in place".with(host, keys)
  requires_when_unmet "babushka bootstrapped".with(host)
  requires_when_unmet "git remote".with(env, app_user, host)

  meet do
    as("root") do
      # First, UTF-8 everything. (A new shell is required to test this, hence 2 runs.)
      failable_remote_babushka "common:set.locale", locale_name: "en_AU"
      remote_babushka "common:set.locale", locale_name: "en_AU"

      # Build ruby separately, because it changes the ruby binary for subsequent deps.
      remote_babushka "conversation:ruby.src", version: "2.4.2", patchlevel: "p198"

      # All the system-wide config for this app, like packages and user accounts.
      remote_babushka "conversation:system provisioned", host_name: host_name, env: env, app_name: app_name, app_user: app_user, key: keys, mailgun_password: mailgun_password
    end

    as(app_user) do
      # This has to run on a separate login from 'deploy user setup', which requires zsh to already be active.
      remote_babushka "conversation:user setup", key: keys

      # Set up the app user for deploys: db user, env vars, and ~/current.
      remote_babushka "conversation:deploy user setup", env: env, app_name: app_name, domain: domain
    end

    # The initial deploy.
    Dep("common:pushed.push").meet(ref, env)

    as(app_user) do
      # Now that the code is in place, provision the app.
      remote_babushka "conversation:app provisioned", env: env, host: host, domain: domain, app_name: app_name, app_user: app_user, app_root: app_root, key: keys
    end

    as("root") do
      # Lastly, revoke sudo to lock the box down per-user.
      remote_babushka "conversation:passwordless sudo removed"
    end

    @run = true
  end
end

dep "apt configured" do
  requires [
    "apt-transport-https.bin",
    "apt sources",
    "apt packages removed".with([/apache/i, /mysql/i, /php/i, /dovecot/]),
    "upgrade apt packages"
  ]
end

dep "system provisioned", :host_name, :env, :app_name, :app_user, :key, :mailgun_password, :datadog_api_key, :datadog_postgres_password do
  requires [
    "localhost hosts entry",
    "hostname".with(host_name),
    "utc",
    "secured ssh logins",
    "firewall rules",
    "papertrail config",
    "core software",
    "local caching dns server",
    "lax host key checking",
    "admins can sudo",
    "tmp cleaning grace period",
    "configured.postfix".with(mailgun_password),
    "memcached",
    "#{app_name} packages",
    "user setup".with(key: key),
    "#{app_name} system".with(app_user, key, env),
    "user setup for provisioning".with(app_user, key),
    "datadog agent installed".with(datadog_api_key: datadog_api_key, datadog_postgres_password: datadog_postgres_password)
  ]
  setup do
    unmeetable! "This dep has to be run as root." unless shell("whoami") == "root"
  end
end

dep "app provisioned", :env, :host, :domain, :app_name, :app_user, :app_root, :key do
  requires [
    "#{app_name} app".with(env, host, domain, app_user, app_root, key)
  ]
  setup do
    unmeetable! "This dep has to be run as the app user, #{app_user}." unless shell("whoami") == app_user
  end
end

# Ensures that the SSL certs are copied onto the server. They should be located
# in the `config/ssl` directory of the app.
dep 'app certs installed', :host do
  src_dir = 'config/ssl'.p
  target_dir = '/etc/ssl'.p
  filter = "--include='*.crt' --include='*.key'"

  met? do
    if !src_dir.exists?
      # Don't bother checking if there are no certs.
      true
    else
      shell("rsync -cinr #{filter} #{src_dir}/ root@#{host}:#{target_dir}/") == ''
    end
  end

  meet do
    log_shell 'Installing certs', "rsync -acz #{filter} #{src_dir}/ root@#{host}:#{target_dir}/"
  end
end
