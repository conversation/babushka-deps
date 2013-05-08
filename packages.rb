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

dep 'imagemagick.bin' do
  provides %w[compare animate convert composite conjure import identify stream display montage mogrify]
end

dep 'libssl headers.managed' do
  installs {
    via :apt, 'libssl-dev'
    via :yum, 'openssl-devel'
  }
  provides []
end

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

dep 'logrotate.managed'

dep 'memcached.bin'

dep 'nc.bin'

dep 'pcre.lib' do
  installs 'libpcre3-dev'
end

dep 'pg.gem' do
  requires 'postgres.bin'
  provides []
end

dep 'phantomjs' do
  requires {
    on :linux, 'phantomjs.src'
    on :osx, 'phantomjs.bin'
  }
end

dep 'phantomjs.bin'

dep 'phantomjs.src' do
  source 'http://phantomjs.googlecode.com/files/phantomjs-1.4.1-source.tar.gz'
  configure { shell 'qmake-qt4' }
  install { sudo 'cp bin/phantomjs /usr/local/bin/' }
  requires 'qt-dev.lib'
end

dep 'pv.bin'

dep 'readline headers.managed' do
  installs {
    on :lenny, 'libreadline5-dev'
    via :apt, 'libreadline6-dev'
  }
  provides []
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

dep 'ssl.lib' do
  installs {
    via :apt, 'libssl-dev'
    via :yum, 'openssl-devel'
  }
end

dep 'tidy.bin'

dep 'uwsgi.pip'

dep 'whiptail.bin'

dep 'whisper.pip'

dep 'yaml headers.managed' do
  installs {
    via :brew, 'libyaml'
    via :apt, 'libyaml-dev'
  }
  provides []
end

dep 'zlib.lib' do
  installs {
    via :apt, 'zlib1g-dev'
    via :yum, 'zlib-devel'
  }
end
