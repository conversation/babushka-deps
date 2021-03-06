dep "schema exists", :username, :db_name, :schema_name do
  requires "postgres access".with(username: username)

  met? do
    raw_shell("psql #{db_name} -t -c '\\dn'", as: "postgres").stdout.val_for(schema_name)
  end

  meet do
    sudo %Q{psql #{db_name} -c 'CREATE SCHEMA "#{schema_name}" AUTHORIZATION "#{username}"'}, as: "postgres"
  end
end

dep "postgres extension", :username, :db_name, :extension do
  requires "existing db".with(username, db_name)

  met? do
    Util.psql(%(SELECT count(*) FROM pg_extension WHERE extname = '#{extension}'), db: db_name).to_i > 0
  end

  meet do
    Util.psql(%(CREATE EXTENSION "#{extension}"), db: db_name)
  end
end

dep "postgres", :version do
  version.default!("10.1")

  requires [
    "postgres config".with(version),
    "postgres auth config".with(version)
  ]
end

dep "postgres config", :version do
  requires "postgres.bin".with(version)
  requires "postgres cert".with(version)

  def current_settings
    Hash[
      Util.psql("SELECT name, setting FROM pg_settings").split("\n").map do |l|
        l.split("|", 2).map(&:strip)
      end
    ]
  end

  def expected_settings
    # Some settings that we customise, and hence use to test whether
    # our config has been applied.
    {
      "listen_addresses" => "*",
      "superuser_reserved_connections" => "2",
      "work_mem" => "32768",
      "wal_level" => "logical",
      "hot_standby" => "on"
    }
  end

  def minor_version
    Util.minor_version(version)
  end

  met? do
    current_settings.slice(*expected_settings.keys) == expected_settings
  end

  meet do
    render_erb "postgres/postgresql.conf.erb", to: "/etc/postgresql/#{minor_version}/main/postgresql.conf"
    Util.restart_service("postgresql")
    sleep 5
  end
end

dep "postgres cert", :version do
  def data_dir
    "/var/lib/postgresql/#{Util.minor_version(version)}/main"
  end

  met? { "#{data_dir}/server.crt".p.exists? }

  meet do
    # Generate a SSL cert valid for 100 years.
    sudo "mkdir -p #{data_dir}"
    sudo %(openssl req -new -x509 -days 36500 -nodes -text -out #{data_dir}/server.crt -keyout #{data_dir}/server.key -subj "/CN=tc-dev.net")
    sudo "chmod og-rwx #{data_dir}/server.key"
    sudo "chown -R postgres:postgres /var/lib/postgresql"
  end
end

dep "postgres auth config", :version do
  requires "postgres.bin".with(version)

  def erb_template
    "postgres/pg_hba.conf.erb"
  end

  def target
    "/etc/postgresql/#{Util.minor_version(version)}/main/pg_hba.conf"
  end

  met? do
    Babushka::Renderable.new(target).from?(dependency.load_path.parent / erb_template)
  end

  meet do
    render_erb erb_template, to: target, sudo: true
  end
end

dep "existing data", :username, :db_name do
  requires "existing db".with(username, db_name)

  met? do
    shell(
      %Q{psql #{db_name} -t -c "SELECT count(*) FROM pg_tables WHERE schemaname NOT IN ('pg_catalog','information_schema')"}
    ).to_i.tap do |tables|
      if tables > 0
        log_ok "There are already #{tables} tables."
      else
        unmeetable! <<-MSG
The '#{db_name}' database is empty. Load a database dump with:
$ cat #{db_name}.psql | ssh #{username}@#{shell('hostname -f')} 'psql #{db_name}'
        MSG
      end
    end > 0
  end
end

dep "existing db", :username, :db_name do
  requires "postgres access".with(username: username)

  met? do
    !shell("psql -l") {|shell|
      shell.stdout.split("\n").grep(/^\s*#{db_name}\s+\|/)
    }.empty?
  end

  meet do
    shell "createdb -O '#{username}' '#{db_name}'"
  end
end

dep "postgres access", :username, :password, :flags do
  requires "postgres.bin"

  username.default(shell("whoami"))

  # Allow new users to create databases by default.
  flags.default!("--createdb")

  met? { !Util.psql("\\du").split("\n").grep(/^\W*\b#{username}\b/).empty? }

  meet do
    shell "createuser #{flags} #{username}", as: "postgres"
    Util.psql("ALTER USER #{username} WITH PASSWORD '#{password}'") if password.set?
  end
end

dep "postgres.bin", :version do
  def enable_postgres
    log_shell "Enabling postgres...", "systemctl enable postgresql", sudo: true
  end

  def start_postgres
    log_shell "Starting postgres...", "systemctl start postgresql", sudo: true
  end

  version.default!("10.1")
  requires "common:set.locale"

  requires_when_unmet do
    on :apt, "keyed apt source".with(
      uri: "http://apt.postgresql.org/pub/repos/apt/",
      release: "xenial-pgdg",
      repo: "main",
      key_sig: "ACCC4CF8",
      key_uri: "https://www.postgresql.org/media/keys/ACCC4CF8.asc"
    )
  end

  installs do
    via :apt, [
      "postgresql-#{Util.minor_version(owner.version)}",
      "postgresql-client-#{Util.minor_version(owner.version)}",
      "libpq-dev"
    ]
    via :brew, "postgresql"
  end

  after do
    enable_postgres
    start_postgres
  end

  provides "psql >= #{version}"
end

dep "postgresql-contrib.lib" do
  installs do
    via :apt, "postgresql-contrib"
    otherwise []
  end
end

dep "postgresql-repack.bin", :version do
  version.default!("10.1")
  requires "postgres.bin".with(version: version)
  provides "pg_repack"

  installs do
    via :apt, "postgresql-#{Util.minor_version(owner.version)}-repack"
    otherwise []
  end
end
