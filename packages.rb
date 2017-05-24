dep 'aptitude.bin'

dep 'aspell.bin'

dep 'aspell dictionary.lib' do
  requires 'aspell.bin'
  installs {
    on :linux, 'aspell-en', 'aspell-fr', 'libaspell-dev'
    otherwise []
  }
end

dep 'bundler.gem' do
  provides 'bundle'
end

dep 'collectd.bin' do
  met? {
    log_shell("checking for collectd", "which collectd")
  }
  meet {
    # specify the install command directly to prevent all the recommended packages being installed
    log_shell("installing collectd", "apt-get install collectd collectd-dev --no-install-recommends -y", :sudo => true)
  }
end

dep 'nodejs.bin', :version do
  version.default!('6.10.0')
  requires_when_unmet {
    on :apt, 'keyed apt source'.with(
      :uri => 'https://deb.nodesource.com/node_6.x',
      :release => 'trusty',
      :repo => 'main',
      :key_sig => '68576280',
      :key_uri => 'https://deb.nodesource.com/gpgkey/nodesource.gpg.key'
    )
  }
  installs {
    via :apt, "nodejs"
    via :brew, "node"
  }
  provides "node ~> #{version}"
end

dep 'coffeescript.bin', :version do
  version.default!('1.4.0')
  requires 'nodejs.bin'
  provides "coffee >= #{version}"
end

dep 'curl.lib' do
  installs {
    on :osx, [] # It's provided by the system.
    via :apt, 'libcurl4-openssl-dev'
    otherwise 'curl' # Assume it's part of curl.
  }
end

dep 'fastly.gem' do
  provides []
end

dep 'git-smart.gem' do
  provides %w[git-smart-log git-smart-merge git-smart-pull]
end

dep 'htop.bin'

dep 'imagemagick.bin' do
  provides %w[compare animate convert composite conjure import identify stream display montage mogrify]
end

dep 'iotop.bin'

dep 'jnettop.bin'

dep 'libxml.lib' do
  installs {
    via :apt, 'libxml2-dev'
  }
end

dep 'libxslt.lib' do
  installs { via :apt, 'libxslt1-dev' }
end

dep 'edit.lib' do
  installs 'libedit-dev'
end

dep 'ffi.lib' do
  installs { via :apt, 'libffi-dev' }
end

dep 'logrotate.bin'

dep 'lsof.bin'

dep 'memcached.bin'

dep 'nc.bin'

dep 'nmap.bin'

dep 'ntpd.bin' do
  installs { via :apt, 'ntp' }
end

dep 'pcre.lib' do
  installs 'libpcre3-dev'
end

dep 'libtag.lib' do
  installs {
    via :apt, 'libtag1-dev'
    via :brew, 'taglib'
  }
end

dep 'pngquant.bin'

dep 'pv.bin'

dep 'python-dateutil.lib'

dep 'readline.lib' do
  installs {
    on :lenny, 'libreadline5-dev'
    via :apt, 'libreadline6-dev'
  }
end

dep 'qt-dev.lib' do
  installs {
    on :apt, 'libqt4-dev', 'libqtwebkit-dev', 'qt4-qmake'
  }
end

dep 'raca.gem' do
  provides []
end

dep 'rcconf.bin' do
  requires 'whiptail.bin'
end

dep 's3cmd.bin' do
  requires 'whiptail.bin'
end

dep 'sasl.lib' do
  installs {
    via :brew, 'libsasl2'
    via :apt, 'libsasl2-dev'
  }
end

dep 'selinux.lib' do
  installs 'libselinux1-dev'
end

dep 'socat.bin'

dep 'sshd.bin' do
  installs {
    via :apt, 'openssh-server'
  }
end

dep 'ssl.lib' do
  installs {
    via :apt, 'libssl-dev'
    via :yum, 'openssl-devel'
  }
end

dep 'tidy.bin'

dep 'tmux.bin'

dep 'traceroute.bin'

dep 'tree.bin'

dep 'trickle.bin'

dep 'unbound.bin' do
  met? {
    in_path?("unbound")
  }
  meet {
    log_shell("installing unbound", "env DEBCONF_TERSE='yes' DEBIAN_PRIORITY='critical' DEBIAN_FRONTEND='noninteractive' apt-get install -y -o Dpkg::Options::='--force-confold' unbound", :sudo => true)
  }
end

dep 'vim.bin'

dep 'whiptail.bin'

dep 'yaml.lib' do
  installs {
    via :brew, 'libyaml'
    via :apt, 'libyaml-dev'
  }
end

dep 'zlib.lib' do
  installs {
    via :apt, 'zlib1g-dev'
    via :yum, 'zlib-devel'
  }
end
