# Bug: this dep only checks for SELECT access, so if you're adding other privileges
# you need to start from none at all.
dep 'db access', :grant, :db_name, :schema, :username, :check_table do
  grant.default!('SELECT')
  schema.default!('public')
  check_table.default!('users')
  requires 'postgres access'.with(:username => username)
  met? {
    shell? %Q{psql #{db_name} -c 'SELECT * FROM #{check_table} LIMIT 1'}, :as => username
  }
  meet {
    %w[TABLES SEQUENCES].each {|objects|
      sudo %Q{psql #{db_name} -c 'GRANT #{grant} ON ALL #{objects} IN SCHEMA "#{schema}" TO "#{username}"'}, :as => 'postgres'
    }
  }
end

dep 'table exists', :username, :db_name, :table_name, :table_schema do
  if table_name['.']
    requires 'schema exists'.with(username, db_name, table_name.to_s.split('.', 2).first)
  end
  met? {
    shell? "psql #{db_name} -t -c '\\d #{table_name}'", :as => username
  }
  meet {
    sudo %Q{psql #{db_name} -c 'CREATE TABLE #{table_name} (#{table_schema})'}, :as => username
  }
end

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
  requires [
    'postgres config'.with(version),
    'postgres auth config'.with(version)
  ]
end

dep 'postgres config', :version do
  requires 'postgres.bin'.with(version)
  def minor_version
    version.to_s.scan(/^\d\.\d/).first
  end
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
      'listen_addresses' => '',
      'superuser_reserved_connections' => '2',
      'work_mem' => '32768',
      'wal_level' => 'logical',
      'hot_standby' => 'on'
    }
  end
  met? {
    current_settings.slice(*expected_settings.keys) == expected_settings
  }
  meet {
    render_erb "postgres/postgresql.conf.erb", :to => "/etc/postgresql/#{minor_version}/main/postgresql.conf"
    log_shell "Restarting postgres", "/etc/init.d/postgresql restart", :as => 'postgres'
  }
end

dep 'postgres auth config', :version do
  requires 'postgres.bin'.with(version)

  def minor_version
    version.to_s.scan(/^\d\.\d/).first
  end
  def erb_template
    "postgres/pg_hba.conf.erb"
  end
  def target
    "/etc/postgresql/#{minor_version}/main/pg_hba.conf"
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
  def minor_version
    version.to_s.scan(/^\d\.\d/).first
  end
  version.default!('9.6.1')
  requires 'common:set.locale'
  requires_when_unmet {
    on :apt, 'keyed apt source'.with(
      :uri => 'http://apt.postgresql.org/pub/repos/apt/',
      :release => 'trusty-pgdg',
      :repo => 'main',
      :key_sig => 'ACCC4CF8',
      :key_uri => 'https://www.postgresql.org/media/keys/ACCC4CF8.asc'
    )
  }
  installs {
    via :apt, [
      "postgresql-#{owner.minor_version}",
      "postgresql-client-#{owner.minor_version}",
      "libpq-dev"
    ]
    via :brew, "postgresql"
  }
  provides "psql >= #{version}"
end

dep 'postgresql-contrib.lib', :version do
  def minor_version
    version.to_s.scan(/^\d\.\d/).first
  end
  installs {
    via :apt, "postgresql-contrib-#{owner.minor_version}"
    otherwise []
  }
end

dep 'pg_repack.src', :version, :postgres_minor_version do
  version.default!('1.3.1')
  postgres_minor_version.default!("9.6")
  source "http://api.pgxn.org/dist/pg_repack/#{version}/pg_repack-#{version}.zip"
  requires [
    'edit.lib',
    'selinux.lib',
    'postgresql server dev.bin'.with(postgres_minor_version)
  ]

  def executable_path
    "/usr/lib/postgresql/#{postgres_minor_version}/bin/pg_repack"
  end

  configure {
    true #nothing
  }
  build { log_shell "build", "make" }
  install { log_shell "install", "make install", :sudo => true }
  met? {
    File.executable?(executable_path)
  }
end

dep 'postgresql server dev.bin', :postgres_minor_version do
  postgres_minor_version.default!("9.6")
  installs {
    via :apt, "postgresql-server-dev-#{owner.postgres_minor_version}"
    otherwise []
  }
  met? {
    raw_shell("dpkg -l").stdout.include?("postgresql-server-dev-#{postgres_minor_version}")
  }
end
