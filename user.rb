dep 'user setup', :username, :key do
  username.default(shell('whoami'))
  requires [
    'dot files'.with(:username => username),
    'passwordless ssh logins'.with(username, key),
    'public key',
    'zsh'.with(username)
  ]
end

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

dep 'dot files', :username, :github_user, :repo do
  username.default!(shell('whoami'))
  github_user.default('benhoskings')
  repo.default('dot-files')
  requires 'user exists'.with(:username => username), 'git', 'curl.bin', 'git-smart.gem'
  met? {
    "~#{username}/.dot-files/.git".p.exists?
  }
  meet {
    shell %Q{curl -L "http://github.com/#{github_user}/#{repo}/raw/master/clone_and_link.sh" | bash}, :as => username
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

dep 'www user and group' do
  www_name = Babushka.host.osx? ? '_www' : 'www'
  met? {
    '/etc/passwd'.p.grep(/^#{www_name}\:/) and
    '/etc/group'.p.grep(/^#{www_name}\:/)
  }
  meet {
    sudo "groupadd #{www_name}"
    sudo "useradd -g #{www_name} #{www_name} -s /bin/false"
  }
end
