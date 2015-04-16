dep 'aptitude.bin'

dep 'aspell.bin'

dep 'aspell dictionary.lib' do
  requires 'aspell.bin'
  installs {
    on :linux, 'aspell-en', 'libaspell-dev'
    otherwise []
  }
end

dep 'bundler.gem' do
  provides 'bundle'
end

dep 'nodejs.bin', :version do
  version.default('0.10.25')
  installs {
    via :apt, [
      "nodejs",
      "nodejs-dev",
      "nodejs-legacy"
    ]
    otherwise "node"
  }
  provides {
    via :apt, "nodejs ~> #{owner.version}"
    otherwise "node ~> #{owner.version}"
  }
end

dep 'coffeescript.bin', :version do
  version.default!('1.4.0')
  requires 'nodejs.bin'
  provides "coffee >= #{version}"
end

dep 'curl.lib' do
  installs {
    on :osx, [] # It's provided by the system.
    otherwise 'libcurl4-openssl-dev'
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

dep 'ffi.lib' do
  installs { via :apt, 'libffi-dev' }
end

dep 'logrotate.bin'

dep 'lsof.bin'

dep 'memcached.bin'

dep 'nc.bin'

dep 'nmap.bin'

dep 'ntpdate.bin'

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

dep 'unbound.bin' do
  met? {
    log_shell("checking for unbound", "which unbound")
  }
  meet {
    log_shell("installing unbound", "env DEBCONF_TERSE='yes' DEBIAN_PRIORITY='critical' DEBIAN_FRONTEND='noninteractive' aptitude install -y -o Dpkg::Options::='--force-confold' unbound", :sudo => true)
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
