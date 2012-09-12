dep 'no known_hosts conflicts', :host do
  met? {
    "~/.ssh/known_hosts".p.grep(/\b#{Regexp.escape(host)}\b/).blank?.tap {|result|
      log_ok "#{host} doesn't appear in #{'~/.ssh/known_hosts'.p}." if result
    }
  }
  meet {
    shell "sed -i '' -e '/#{Regexp.escape(host)}/d' ~/.ssh/known_hosts"
  }
end

dep 'public key in place', :host, :keys do
  requires_when_unmet 'no known_hosts conflicts'.with(host)
  met? {
    shell?("ssh -o PasswordAuthentication=no root@#{host} 'true'").tap {|result|
      log "root@#{host} is#{"n't" unless result} accessible via publickey auth.", :as => (:ok if result)
    }
  }
  meet {
    shell "ssh root@#{host} 'mkdir -p ~/.ssh; cat > ~/.ssh/authorized_keys'", :input => keys
  }
end

dep 'babushka bootstrapped', :host do
  met? {
    raw_shell("ssh root@#{host} 'babushka --version'").stdout[/[\d\.]{5,} \([0-9a-f]{7,}\)/].tap {|result|
      log_ok "#{host} is running babushka-#{result}." if result
    }
  }
  meet {
    shell %{ssh root@#{host} 'bash -'}, :input => shell('curl babushka.me/up'), :log => true
  }
end

dep 'host provisioned', :host, :ref, :env, :app_user, :domain, :app_root, :keys, :check_path, :expected_content do

  def as user, &block
    previous_user, @user = @user, user
    yield
  ensure
    @user = previous_user
  end

  def remote_shell *cmd
    host_spec = "#{@user || 'root'}@#{host}"
    opening_message = [
      host_spec.colorize("on grey"), # user@host spec
      cmd.map {|i| i.sub(/^(.{50})(.{3}).*/m, '\1...') }.join(' ') # the command, with long args truncated
    ].join(' $ ')
    log opening_message, :closing_status => opening_message do
      shell "ssh", "-A", host_spec, cmd.map{|i| "'#{i}'" }.join(' '), :log => true
    end
  end

  def remote_babushka dep_spec, args = {}
    remote_args = [
      '--defaults',
      ('--update' if Babushka::Base.task.opt(:update)),
      ('--debug'  if Babushka::Base.task.opt(:debug)),
      ('--colour' if $stdin.tty?),
      '--show-args'
    ].compact

    remote_args.concat args.keys.map {|k| "#{k}=#{args[k]}" }

    remote_shell(
      'babushka',
      dep_spec,
      *remote_args
    ).tap {|result|
      unmeetable! "The remote babushka reported an error." unless result
    }
  end

  def failable_remote_babushka dep_spec, args = {}
    remote_babushka(dep_spec, args)
  rescue Babushka::UnmeetableDep => ex
    log "That remote run was marked as failable; moving on."
    false
  end

  requires_when_unmet 'public key in place'.with(host, keys)
  requires_when_unmet 'babushka bootstrapped'.with(host)
  requires_when_unmet 'git remote'.with(env, app_user, host)

  keys.default!((dependency.load_path.parent / 'config/authorized_keys').read)
  domain.default!(app_user) if env == 'production'
  app_root.default!('~/current')
  check_path.default!('/health')

  met? {
    cmd = raw_shell("curl --connect-timeout 2 -v -H 'Host: #{domain}' http://#{host}#{check_path}")

    if !cmd.ok?
      log "Couldn't connect to http://#{host}."
    else
      log_ok "#{host} is up."

      if cmd.stderr.val_for('Status') != '200 OK'
        @should_confirm = true
        log_warn "http://#{domain}#{check_path} on #{host} reported a problem:\n#{cmd.stdout}"
      else
        log_ok "#{domain}#{check_path} responded with 200 OK."

        check_output = shell("curl -v -H 'Host: #{domain}' http://#{host}")

        if !check_output[/#{Regexp.escape(expected_content)}/]
          @should_confirm = true
          log_warn "#{domain} on #{host} doesn't contain '#{expected_content}'."
        else
          log_ok "#{domain} on #{host} contains '#{expected_content}'."
        end
      end
    end
  }

  prepare {
    unmeetable! "OK, bailing." if @should_confirm && !confirm("Sure you want to provision #{domain} on #{host}?")
  }

  meet {
    as('root') {
      # First, UTF-8 everything. (A new shell is required to test this, hence 2 runs.)
      failable_remote_babushka 'benhoskings:set.locale', :locale_name => 'en_AU'
      remote_babushka 'benhoskings:set.locale', :locale_name => 'en_AU'

      # Build ruby separately, because it changes the ruby binary for subsequent deps.
      remote_babushka 'benhoskings:ruby.src', :version => '1.9.3', :patchlevel => 'p194'

      # All the system-wide config for this app, like packages and user accounts.
      remote_babushka "conversation:system provisioned", :env => env, :app_user => app_user, :key => keys
    }

    as(app_user) {
      # This has to run on a separate login from 'deploy user setup', which requires zsh to already be active.
      remote_babushka 'benhoskings:user setup', :key => keys

      # Set up the app user for deploys: db user, env vars, and ~/current.
      remote_babushka 'conversation:deploy user setup', :env => env
    }

    # The initial deploy.
    Dep('benhoskings:pushed.push').meet(ref, env)

    as(app_user) {
      # Now that the code is in place, provision the app.
      remote_babushka "conversation:app provisioned", :env => env, :domain => domain, :app_user => app_user, :app_root => app_root, :key => keys
    }

    as('root') {
      # Lastly, revoke sudo to lock the box down per-user.
      remote_babushka "benhoskings:passwordless sudo removed"
    }
  }
end

dep 'system provisioned', :env, :app_user, :key do
  requires [
    'benhoskings:utc',
    'conversation:localhost hosts entry',
    'conversation:apt sources',
    'benhoskings:apt packages removed'.with(/apache|mysql|php/i),
    'conversation:running.postfix',
    'benhoskings:system'.with(:host_name => "#{env}-#{Time.now.strftime('%Y-%m-%d')}"),
    'benhoskings:user setup'.with(:key => key),
    "#{app_user} packages",
    "#{app_user} system".with(app_user, key),
    'benhoskings:user setup for provisioning'.with(app_user, key)
  ]
end

dep 'app provisioned', :env, :domain, :app_user, :app_root, :key do
  requires [
    "#{app_user} app".with(env, domain, app_user, app_root, key),

    # Lastly, boot the app.
    "benhoskings:unicorn running".with(:app_root => "~/current", :env => env)
  ]
end
