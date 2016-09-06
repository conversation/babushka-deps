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
  version.default!('0.10.25')
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
    via :apt, 'libcurl4-openssl-dev'
    otherwise 'curl' # Assume it's part of curl.
  }
end

dep 'fastly.gem' do
  provides []
end

# Once we're using Ubuntu 16.04 in production, we can simplify this dep to just:
#
#  dep "geoipupdate.bin"
dep 'geoipupdate.bin', :version do
  requires_when_unmet {
    on :apt, 'keyed apt source'.with(
      :uri => 'http://ppa.launchpad.net/maxmind/ppa/ubuntu',
      :release => 'trusty',
      :repo => 'main',
      :key_sig => 'DE742AFA',
      :key_uri => 'http://keyserver.ubuntu.com:11371/pks/lookup?op=get&search=0xDE1997DCDE742AFA'
    )
  }
  installs {
    via :apt, "geoipupdate"
    via :brew, "geoipupdate"
  }
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

dep 's3cmd' do
  requires "python-dateutil.lib"

 def source_url
   "http://mirrors.kernel.org/ubuntu/pool/universe/s/s3cmd/s3cmd_1.5.0~rc1-2_all.deb"
 end

 met? {
   log_shell("checking for s3cmd", "which s3cmd")
 }
 meet {
   if Babushka.host.linux?
     Babushka::Resource.get(source_url) { |path|
       log_shell("installing s3cmd", "dpkg -i #{path}", :sudo => true)
     }
   else
     unmeetable! "Not sure how to install s3cmd on this system."
   end
 }
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
