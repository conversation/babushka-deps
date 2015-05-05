dep 'postgres master', :version, :local_user, :key do
  local_user.default!('standby')

  requires [
    'postgres access'.with(local_user, '-SDR --replication'),
    'passwordless ssh logins'.with(local_user, key)
  ]
end

dep 'postgres standby', :env, :version, :local_user, :local_port, :remote_user, :remote_host do
  env.default(ENV['RACK_ENV'])
  local_port.default!(5433)
  remote_host.default({
    'production' => 'theconversation.edu.au',
    'staging' => 'staging.tc-dev.net'
  }[env])

  requires [
    'postgres socket tunnel'.with(local_user, local_port, remote_user, remote_host),
    'postgres recovery config'.with(version, local_port, remote_user)
  ]
end

dep 'postgres recovery config', :version, :local_port, :remote_user do
  def minor_version
    version.to_s.scan(/^\d\.\d/).first
  end
  requires 'postgres.bin'.with(version)
  def psql cmd
    shell?("psql postgres -c 'SELECT 1'", :as => 'postgres') &&
    shell("psql postgres -t", :as => 'postgres', :input => cmd).strip
  end
  met? {
    psql('SELECT pg_is_in_recovery()') == 't'
  }
  meet {
    render_erb "postgres/recovery.conf.erb", :to => "/var/lib/postgresql/#{minor_version}/main/recovery.conf"
    shell "chown postgres:postgres /var/lib/postgresql/#{minor_version}/main/recovery.conf"
    log_shell "Restarting postgres", "initctl restart postgresql", :as => 'postgres'
  }
end

dep 'postgres socket tunnel', :local_user, :local_port, :remote_user, :remote_host do
  local_user.default!('postgres')
  remote_user.default!('standby')

  requires 'socat.bin'

  def local_socket
    "/var/run/postgresql/.s.PGSQL.#{local_port}"
  end
  def remote_socket
    "/var/run/postgresql/.s.PGSQL.5432"
  end
  def tunnel_config
    "/etc/init/postgres_socket_tunnel.conf"
  end

  met? {
    local_socket.p.exists? &&
    shell("lsof #{local_socket}").val_for('socat').ends_with?(local_socket) &&
    Babushka::Renderable.new(tunnel_config).from?(dependency.load_path.parent / "replication/postgres_socket_tunnel.conf.erb")
  }
  meet {
    render_erb 'replication/postgres_socket_tunnel.conf.erb', :to => tunnel_config
    sudo "initctl start postgres_socket_tunnel; true"
  }
end

dep 'postgres replication monitoring', :version, :test_user do

  requires 'postgres.bin'.with(version)

  met? {
    shell? 'psql postgres -c "SELECT replication_status()"', :as => test_user
  }
  meet {
    shell 'psql postgres', :as => 'postgres', :input => %q{
      BEGIN;

      CREATE TYPE replication_tuple AS (
        started_at timestamp with time zone,
        master_position text,
        standby_position text,
        standby_lag numeric
      );

      CREATE FUNCTION replication_status() RETURNS SETOF replication_tuple AS
        'SELECT
          backend_start,
          pg_current_xlog_location(),
          replay_location,
          pg_xlog_location_diff(pg_current_xlog_location(), replay_location)
        FROM
          pg_stat_replication'
      LANGUAGE SQL SECURITY DEFINER
      -- Put pg_temp last so its objects can't shadow those used in the function.
      SET search_path = admin, pg_temp;

      REVOKE ALL ON FUNCTION replication_status() FROM PUBLIC;
      GRANT EXECUTE ON FUNCTION replication_status() TO PUBLIC;

      COMMIT;
    }
  }
end
