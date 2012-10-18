dep 'read-only schema access', :username, :owner_name, :db_name, :schema_name, :check_table do
  requires 'schema exists'.with(owner_name, db_name, schema_name)
  met? {
    cmd = raw_shell("psql #{db_name} -t -c 'SELECT * FROM #{check_table} LIMIT 1'", :as => username)
    # If we have schema access, the only reason this should fail is if we can't access the table itself.
    cmd.ok? || cmd.stderr['permission denied for relation']
  }
  meet {
    sudo %Q{psql #{db_name} -c 'GRANT USAGE ON SCHEMA "#{schema_name}" TO "#{username}"'}, :as => 'postgres'
  }
end

dep 'read-only db access', :db_name, :schema, :username, :check_table do
  schema.default!('public')
  check_table.default!('users')
  requires 'benhoskings:postgres access'.with(:username => username)
  met? { shell? %Q{psql #{db_name} -c 'SELECT * FROM #{check_table} LIMIT 1'}, :as => username }
  meet { sudo %Q{psql #{db_name} -c 'GRANT SELECT ON ALL TABLES IN SCHEMA "#{schema}" TO "#{username}"'}, :as => 'postgres' }
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
  requires 'benhoskings:postgres access'.with(:username => username)
  met? {
    raw_shell("psql #{db_name} -t -c '\\dn'", :as => 'postgres').stdout.val_for(schema_name)
  }
  meet {
    sudo %Q{psql #{db_name} -c 'CREATE SCHEMA "#{schema_name}" AUTHORIZATION "#{username}"'}, :as => 'postgres'
  }
end

dep 'schema ownership', :username, :db_name, :schema_name do
  requires 'schema exists'.with(username, db_name, schema_name)
  met? {
    raw_shell("psql #{db_name} -t -c '\\dn'", :as => 'postgres').stdout.val_for(schema_name) == "| #{username}"
  }
  meet {
    sudo %Q{psql #{db_name} -c 'ALTER SCHEMA "#{schema_name}" OWNER TO "#{username}"'}, :as => 'postgres'
  }
end

dep 'postgres extension', :username, :db_name, :extension do
  requires 'benhoskings:existing postgres db'.with(username, db_name)

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
  requires 'postgres config'.with(version)
end

dep 'postgres config', :version do
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
      'listen_addresses' => '',
      'superuser_reserved_connections' => '2',
      'work_mem' => '32768'
    }
  end
  met? {
    current_settings.slice(*expected_settings.keys) == expected_settings
  }
  meet {
    render_erb "postgres/postgresql.conf.erb", :to => "/etc/postgresql/#{version}/main/postgresql.conf"
    log_shell "Restarting postgres", "/etc/init.d/postgresql restart", :as => 'postgres'
  }
end

dep 'postgres.bin', :version do
  version.default('9.2')
  requires 'benhoskings:set.locale'
  requires_when_unmet {
    on :apt, 'ppa'.with('ppa:pitti/postgresql')
  }
  installs {
    via :apt, ["postgresql-#{owner.version}", "libpq-dev"]
    via :brew, "postgresql"
  }
  provides "psql ~> #{version}.0"
end

dep 'postgresql-contrib.lib' do
  installs {
    via :apt, 'postgresql-contrib'
    otherwise []
  }
end
