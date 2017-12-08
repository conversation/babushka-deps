dep "postgres master", :username, :password do
  username.default!("standby")

  # Create the standby user with replication privileges.
  requires "postgres access".with(username: username, flags: "--replication")
end

dep "postgres standby", :host, :env, :version, :username, :password do
  host.default({
    "production" => "prod-master.tc-dev.net",
    "staging" => "staging.tc-dev.net"
  }[env])
  env.default(ENV["RACK_ENV"])
  version.default!("10.1")
  username.default!("standby")

  requires "postgres recovery config".with(host: host, version: version, username: username, password: password)
end

dep "postgres recovery config", :host, :version, :username, :password do
  requires "postgres.bin".with(version)

  def psql(cmd)
    shell?("psql postgres -c 'SELECT 1'", as: "postgres") &&
    shell("psql postgres -t", as: "postgres", input: cmd).strip
  end

  def minor_version
    Util.minor_version(version)
  end

  met? do
    psql("SELECT pg_is_in_recovery()") == "t"
  end

  meet do
    render_erb "postgres/recovery.conf.erb", to: "/var/lib/postgresql/#{minor_version}/main/recovery.conf"
    shell "chown postgres:postgres /var/lib/postgresql/#{minor_version}/main/recovery.conf"
    Util.restart_service("postgresql")
  end
end

dep "postgres replication monitoring", :version, :test_user do
  requires "postgres.bin".with(version)

  met? do
    shell? 'psql postgres -c "SELECT replication_status()"', as: test_user
  end

  meet do
    shell "psql postgres", as: "postgres", input: %q{
      BEGIN;

      CREATE TYPE replication_tuple AS (
        started_at timestamp with time zone,
        master_position pg_lsn,
        standby_position pg_lsn,
        standby_lag numeric
      );

      CREATE FUNCTION replication_status() RETURNS SETOF replication_tuple AS
        'SELECT
          backend_start,
          pg_current_wal_lsn(),
          replay_lsn,
          pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)
        FROM
          pg_stat_replication'
      LANGUAGE SQL SECURITY DEFINER
      -- Put pg_temp last so its objects can't shadow those used in the function.
      SET search_path = admin, pg_temp;

      REVOKE ALL ON FUNCTION replication_status() FROM PUBLIC;
      GRANT EXECUTE ON FUNCTION replication_status() TO PUBLIC;

      COMMIT;
    }
  end
end
