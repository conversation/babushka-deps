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

# Actually headers, but 'lib' will do the trick for now.
dep 'curl.lib' do
  installs 'libcurl4-openssl-dev'
end

dep 'libxml.lib' do
  installs { via :apt, 'libxml2-dev' }
end

dep 'memcached.bin'

dep 'libxslt.lib' do
  installs { via :apt, 'libxslt1-dev' }
end

dep 'imagemagick.bin' do
  provides %w[compare animate convert composite conjure import identify stream display montage mogrify]
end

dep 'coffeescript.src', :version do
  version.default!('1.3.3')
  requires 'nodejs.bin'
  source "http://github.com/jashkenas/coffee-script/tarball/#{version}"
  provides "coffee ~> #{version}"

  configure { true }
  build { shell "bin/cake build" }
  install { shell "bin/cake install", :sudo => Babushka::SrcHelper.should_sudo? }
end

dep 'nodejs.bin', :version do
  requires {
    on :apt, 'our apt source'
  }
  version.default!('0.6.10')
  met? {
    in_path? "node ~> #{version}"
  }
  installs {
    via :apt, 'nodejs'
    via :brew, 'node'
  }
end

dep 'npm.bin', :version do
  requires {
    on :apt, 'our apt source', 'nodejs.bin'
    otherwise 'nodejs.bin'
  }
  version.default!('1.1.0')
  met? {
    in_path? "npm ~> #{version}"
  }
end

dep 'pv.bin'

dep 'socat.bin'

dep 'supervisor.bin' do
  requires 'meld3.pip'
  provides 'supervisord', 'supervisorctl'
end

dep 'meld3.pip' do
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

dep 'qt-dev.lib' do
  installs {
    on :apt, 'libqt4-dev', 'libqtwebkit-dev', 'qt4-qmake'
  }
end

dep 'postgresql-contrib.lib' do
  installs {
    via :apt, 'postgresql-contrib'
    otherwise []
  }
end

dep 'tidy.bin'

dep 'graphite-web.pip' do
  requires %w[carbon.pip whisper.pip django.pip django-tagging.pip uwsgi.pip simplejson.pip]
end

dep 'carbon.pip'

dep 'whisper.pip'

dep 'django.pip'

dep 'django-tagging.pip'

dep 'uwsgi.pip'

dep 'simplejson.pip'