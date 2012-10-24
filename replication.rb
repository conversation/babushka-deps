dep 'postgres master', :version, :local_user, :key do
  local_user.default!('standby')

  requires [
    'benhoskings:postgres access'.with(local_user, '-SDR --replication'),
    'benhoskings:passwordless ssh logins'.with(local_user, key)
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
    'postgres socket tunnel.upstart'.with(local_user, local_port, remote_user, remote_host),
    'postgres recovery config'.with(version, local_port, remote_user)
  ]
end

dep 'postgres recovery config', :version, :local_port, :remote_user do
  requires 'postgres.bin'.with(version)
  def psql cmd
    shell?("psql postgres -c 'SELECT 1'", :as => 'postgres') &&
    shell("psql postgres -t", :as => 'postgres', :input => cmd).strip
  end
  met? {
    psql('SELECT pg_is_in_recovery()') == 't'
  }
  meet {
    render_erb "postgres/recovery.conf.erb", :to => "/var/lib/postgresql/#{version}/main/recovery.conf"
    shell "chown postgres:postgres /var/lib/postgresql/#{version}/main/recovery.conf"
    log_shell "Restarting postgres", "/etc/init.d/postgresql restart", :as => 'postgres'
  }
end

dep 'postgres socket tunnel.upstart', :local_user, :local_port, :remote_user, :remote_host do
  local_user.default!('postgres')
  remote_user.default!('standby')

  requires 'socat.bin'

  def local_socket
    "/var/run/postgresql/.s.PGSQL.#{local_port}"
  end
  def remote_socket
    "/var/run/postgresql/.s.PGSQL.5432"
  end

  command %Q{socat UNIX-LISTEN:#{local_socket},fork EXEC:'ssh -C #{remote_user}@#{remote_host} "socat STDIO UNIX-CONNECT:#{remote_socket}"'}
  setuid local_user
  chdir "~#{local_user}".p
  respawn 'true'

  met? {
    local_socket.p.exists? &&
    shell("lsof #{local_socket}").val_for('socat').ends_with?(local_socket)
  }
end
