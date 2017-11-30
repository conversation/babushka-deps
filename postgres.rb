dep 'schema exists', :username, :db_name, :schema_name do
  requires 'postgres access'.with(:username => username)
  met? {
    raw_shell("psql #{db_name} -t -c '\\dn'", :as => 'postgres').stdout.val_for(schema_name)
  }
  meet {
    sudo %Q{psql #{db_name} -c 'CREATE SCHEMA "#{schema_name}" AUTHORIZATION "#{username}"'}, :as => 'postgres'
  }
end

dep 'postgres extension', :username, :db_name, :extension do
  requires 'existing db'.with(username, db_name)

  def psql cmd
    shell("psql #{db_name} -t", :as => 'postgres', :input => cmd).strip
  end

  met? {
    psql(%{SELECT count(*) FROM pg_extension WHERE extname = '#{extension}'}).to_i > 0
  }
  meet {
    psql(%{CREATE EXTENSION "#{extension}"})
  }
end

dep 'postgres', :version do
  version.default!('10.1')

  requires [
    'postgres config'.with(version),
    'postgres auth config'.with(version)
  ]
end

dep 'postgres config', :version do
  requires 'postgres cert'.with(version)
  requires 'postgres.bin'.with(version)

  def psql cmd
    shell("psql postgres -t", :as => 'postgres', :input => cmd).strip
  end
  def current_settings
    Hash[
      psql('SELECT name,setting FROM pg_settings').split("\n").map {|l|
        l.split('|', 2).map(&:strip)
      }
    ]
  end
  def expected_settings
    # Some settings that we customise, and hence use to test whether
    # our config has been applied.
    {
      'listen_addresses' => '*',
      'superuser_reserved_connections' => '2',
      'work_mem' => '32768',
      'wal_level' => 'logical',
      'hot_standby' => 'on'
    }
  end
  def restart_postgres
    log_shell "Restarting postgres...", "systemctl restart postgresql", sudo: true
    sleep 5
  end
  met? {
    current_settings.slice(*expected_settings.keys) == expected_settings
  }
  meet {
    render_erb "postgres/postgresql.conf.erb", :to => "/etc/postgresql/#{DatabaseHelper.minor_version(version)}/main/postgresql.conf"
    restart_postgres
  }
end

dep 'postgres cert', :version do
  def data_dir
    "/var/lib/postgresql/#{DatabaseHelper.minor_version(version)}/main"
  end

  met? { "#{data_dir}/server.crt".p.exists? }

  meet {
    # Generate a SSL cert valid for 100 years.
    sudo "mkdir -p #{data_dir}"
    sudo %(openssl req -new -x509 -days 36500 -nodes -text -out #{data_dir}/server.crt -keyout #{data_dir}/server.key -subj "/CN=tc-dev.net")
    sudo "chmod og-rwx #{data_dir}/server.key"
    sudo "chown -R postgres:postgres /var/lib/postgresql"
  }
end

dep 'postgres auth config', :version do
  requires 'postgres.bin'.with(version)

  def erb_template
    "postgres/pg_hba.conf.erb"
  end
  def target
    "/etc/postgresql/#{DatabaseHelper.minor_version(version)}/main/pg_hba.conf"
  end

  met? {
    Babushka::Renderable.new(target).from?(dependency.load_path.parent / erb_template)
  }
  meet {
    render_erb erb_template, :to => target, :sudo => true
  }
end

dep 'existing data', :username, :db_name do
  requires 'existing db'.with(username, db_name)
  met? {
    shell(
      %Q{psql #{db_name} -t -c "SELECT count(*) FROM pg_tables WHERE schemaname NOT IN ('pg_catalog','information_schema')"}
    ).to_i.tap {|tables|
      if tables > 0
        log_ok "There are already #{tables} tables."
      else
        unmeetable! <<-MSG
The '#{db_name}' database is empty. Load a database dump with:
$ cat #{db_name}.psql | ssh #{username}@#{shell('hostname -f')} 'psql #{db_name}'
        MSG
      end
    } > 0
  }
end

dep 'existing db', :username, :db_name do
  requires 'postgres access'.with(:username => username)
  met? {
    !shell("psql -l") {|shell|
      shell.stdout.split("\n").grep(/^\s*#{db_name}\s+\|/)
    }.empty?
  }
  meet {
    shell "createdb -O '#{username}' '#{db_name}'"
  }
end

dep 'postgres access', :username, :flags do
  requires 'postgres.bin'
  requires 'user exists'.with(:username => username)
  username.default(shell('whoami'))
  flags.default!('-SdR')
  met? { !sudo("echo '\\du' | #{which 'psql'}", :as => 'postgres').split("\n").grep(/^\W*\b#{username}\b/).empty? }
  meet { sudo "createuser #{flags} #{username}", :as => 'postgres' }
end

dep 'postgres.bin', :version do
  def enable_postgres
    log_shell "Enabling postgres...", "systemctl enable postgresql", sudo: true
  end

  def start_postgres
    log_shell "Starting postgres...", "systemctl start postgresql", sudo: true
  end

  version.default!('10.1')
  requires 'common:set.locale'
  requires_when_unmet {
    on :apt, 'keyed apt source'.with(
      :uri => 'http://apt.postgresql.org/pub/repos/apt/',
      :release => 'xenial-pgdg',
      :repo => 'main',
      :key_sig => 'ACCC4CF8',
      :key_uri => 'https://www.postgresql.org/media/keys/ACCC4CF8.asc'
    )
  }
  installs {
    via :apt, [
      "postgresql-#{DatabaseHelper.minor_version(owner.version)}",
      "postgresql-client-#{DatabaseHelper.minor_version(owner.version)}",
      "libpq-dev"
    ]
    via :brew, "postgresql"
  }
  after {
    enable_postgres
    start_postgres
  }
  provides "psql >= #{version}"
end

dep 'postgresql-contrib.lib' do
  installs {
    via :apt, "postgresql-contrib"
    otherwise []
  }
end

dep 'postgresql-repack.bin', :version do
  version.default!('10.1')
  requires 'postgres.bin'.with(:version => version)
  provides "pg_repack"

  installs {
    via :apt, "postgresql-#{DatabaseHelper.minor_version(owner.version)}-repack"
    otherwise []
  }
end
