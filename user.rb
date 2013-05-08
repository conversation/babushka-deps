dep 'user setup for provisioning', :username, :key do
  requires [
    'user exists'.with(:username => username),
    'passwordless ssh logins'.with(username, key),
    'passwordless sudo'.with(username)
  ]
end

dep 'deploy user setup', :env do
  requires [
    # Add a corresponding DB user.
    'postgres access',

    # Set RACK_ENV and friends.
    'app env vars set'.with(:env => env),

    # Configure the ~/current repo to accept deploys.
    'benhoskings:web repo'
  ]
end

dep 'passwordless ssh logins', :username, :key do
  username.default(shell('whoami'))
  def ssh_dir
    "~#{username}" / '.ssh'
  end
  def group
    shell "id -gn #{username}"
  end
  def sudo?
    @sudo ||= username != shell('whoami')
  end
  met? {
    shell? "fgrep '#{key}' '#{ssh_dir / 'authorized_keys'}'", :sudo => sudo?
  }
  meet {
    shell "mkdir -p -m 700 '#{ssh_dir}'", :sudo => sudo?
    shell "cat >> #{ssh_dir / 'authorized_keys'}", :input => key, :sudo => sudo?
    sudo "chown -R #{username}:#{group} '#{ssh_dir}'" unless ssh_dir.owner == username
    sudo "chown -R #{username}:#{group} '#{ssh_dir / 'authorized_keys'}'" unless (ssh_dir / 'authorized_keys').owner == username
    shell "chmod 600 #{(ssh_dir / 'authorized_keys')}", :sudo => sudo?
  }
end

dep 'user exists', :username, :home_dir_base do
  home_dir_base.default(username['.'] ? '/srv/http' : '/home')

  met? {
    '/etc/passwd'.p.grep(/^#{username}:/)
  }
  meet {
    sudo "mkdir -p #{home_dir_base}" and
    sudo "useradd -m -s /bin/bash -b #{home_dir_base} -G admin #{username}" and
    sudo "chmod 701 #{home_dir_base / username}"
  }
end
