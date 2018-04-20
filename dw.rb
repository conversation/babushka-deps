dep(
  'provision dw',
  :aws_secret_access_key,
  :bugsnag_api_key,
  :database_password,
  :domain,
  :env,
  :force,
  :host,
  :keys,
  template: 'remote'
) do
  if env == 'production'
    domain.default!('dw.theconversation.com')
  else
    domain.default!('dw.tc-dev.net')
  end

  force.default!('no')
  keys.default!((dependency.load_path.parent / "config/authorized_keys").read)

  requires_when_unmet "public key in place".with(host, keys)
  requires_when_unmet "babushka bootstrapped".with(host)
  requires_when_unmet 'app certs installed'.with(host: host)

  before do
    shell "scp db/schema.sql root@#{host}:/tmp/"
  end

  met? do
    curl = "curl -v -L --connect-timeout 5 --max-time 30 --resolve #{domain}:80:#{host} --resolve #{domain}:443:#{host}"
    cmd = raw_shell("#{curl} http://#{domain}/health")

    if !cmd.ok?
      log "Couldn't connect to http://#{host}."
      false
    elsif force == 'yes'
      log 'Forcing...'
      false
    else
      log_ok "#{host} is up."

      if cmd.stderr.val_for('Status') != '200 OK'
        log_warn "#{domain} on #{host} reported a problem:\n#{cmd.stdout}"
      else
        log_ok "#{domain} on #{host} responded with 200 OK."
      end

      true
    end
  end

  meet do
    remote_babushka(
      'conversation:dw app',
      aws_secret_access_key: aws_secret_access_key,
      bugsnag_api_key: bugsnag_api_key,
      database_host: "db.#{env}.tc-dev.net",
      database_name: 'dw',
      database_password: database_password,
      database_username: 'dw.theconversation.com',
      domain: domain
    )
  end
end

dep(
  'dw app',
  :aws_secret_access_key,
  :bugsnag_api_key,
  :database_host,
  :database_name,
  :database_password,
  :database_username,
  :domain
) do
  def database_url
    "postgres://#{database_username}:#{database_password}@#{database_host}:5432/#{database_name}"
  end

  requires [
    'dw packages',

    # Ensure root has the superuser role.
    'postgres access'.with(
      username: 'root',
      flags: '--superuser'
    ),

    'postgres access'.with(
      username: database_username,
      password: database_password
    ),

    'existing db'.with(
      db_name: database_name,
      username: database_username
    ),

    'schema loaded'.with(
      db_name: database_name,
      username: database_username,
      schema_path: '/tmp/schema.sql'
    ),

    'docker swarm initialised',

    'docker secret'.with(key: 'dw_aws_secret_access_key', value: aws_secret_access_key),
    'docker secret'.with(key: 'dw_database_url', value: database_url),
    'docker secret'.with(key: 'dw_bugsnag_api_key', value: bugsnag_api_key),

    'proxy vhost enabled.nginx'.with(
      app_name: 'dw',
      domain: domain,
      proxy_port: '9292'
    )
  ]
end

dep 'dw packages' do
  requires [
    'docker.bin',
    'docker-compose',
    'docker-gc'
  ]
end
