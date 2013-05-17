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

dep 'carbon.pip'

dep 'coffeescript.src', :version do
  version.default!('1.3.3')
  requires 'core:nodejs.bin'
  source "https://github.com/jashkenas/coffee-script/archive/#{version}.tar.gz"
  provides "coffee >= #{version}"

  configure { true }
  build { shell "bin/cake build" }
  install { shell "bin/cake install", :sudo => Babushka::SrcHelper.should_sudo? }
end

dep 'curl.lib' do
  installs {
    on :osx, [] # It's provided by the system.
    otherwise 'libcurl4-openssl-dev'
  }
end

dep 'django.pip'

dep 'django-tagging.pip'

dep 'git-smart.gem' do
  provides %w[git-smart-log git-smart-merge git-smart-pull]
end

dep 'graphite-web.pip' do
  requires %w[carbon.pip whisper.pip django.pip django-tagging.pip uwsgi.pip simplejson.pip]
end

dep 'htop.bin'

dep 'imagemagick.bin' do
  provides %w[compare animate convert composite conjure import identify stream display montage mogrify]
end

dep 'iotop.bin'

dep 'jnettop.bin'

dep 'libxml.lib' do
  installs {
    # The latest libxml2 on 12.04 doesn't have a corresponding libxml2-dev.
    on :precise, 'libxml2=2.7.8.dfsg-5.1ubuntu4', 'libxml2-dev=2.7.8.dfsg-5.1ubuntu4'

    via :apt, 'libxml2-dev'
  }
end

dep 'libxslt.lib' do
  installs { via :apt, 'libxslt1-dev' }
end

dep 'logrotate.bin'

dep 'lsof.bin'

dep 'memcached.bin'

dep 'nc.bin'

dep 'nmap.bin'

dep 'pcre.lib' do
  installs 'libpcre3-dev'
end

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

dep 'rcconf.bin' do
  requires 'whiptail.bin'
end

dep 'simplejson.pip'

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

dep 'uwsgi.pip'

dep 'vim.bin'

dep 'whiptail.bin'

dep 'whisper.pip'

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
