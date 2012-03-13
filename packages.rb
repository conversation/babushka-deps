dep 'aspell.managed'

dep 'aspell dictionary.managed', :for => :linux do
  requires 'aspell.managed'
  installs 'aspell-en', 'libaspell-dev'
  provides []
end

dep 'bundler.gem' do
  provides 'bundle'
end

dep 'libxml.managed' do
  installs { via :apt, 'libxml2-dev' }
  provides []
end

dep 'memcached.managed'

dep 'libxslt.managed' do
  installs { via :apt, 'libxslt1-dev' }
  provides []
end

dep 'imagemagick.managed' do
  provides %w[compare animate convert composite conjure import identify stream display montage mogrify]
end

dep 'coffeescript.src', :version do
  version.default!('1.1.2')
  requires 'nodejs.managed'
  source "http://github.com/jashkenas/coffee-script/tarball/#{version}"
  provides 'coffee'

  configure { true }
  build { shell "bin/cake build" }
  install { shell "bin/cake install", :sudo => Babushka::SrcHelper.should_sudo? }
end

dep 'nodejs.managed', :version do
  requires {
    on :apt, 'our apt source'
  }
  version.default!('0.6.10')
  installs {
    via :apt, 'nodejs'
    via :brew, 'node'
  }
  provides "node ~> #{version}"
end

dep 'npm.managed', :version do
  requires {
    on :apt, 'our apt source', 'nodejs.managed'
    otherwise 'nodejs.managed'
  }
  version.default!('1.1.0')
  provides "npm ~> #{version}"
end

dep 'rsync.managed'

dep 'socat.managed'

dep 'supervisor.managed' do
  requires 'meld3.pip'
  provides 'supervisord', 'supervisorctl'
end

dep 'meld3.pip' do
  provides []
end

dep 'phantomjs' do
  requires {
    on :linux, 'phantomjs.src'
    on :osx, dep('phantomjs.managed')
  }
end

dep 'phantomjs.src' do
  source 'http://phantomjs.googlecode.com/files/phantomjs-1.4.1-source.tar.gz'
  configure { shell 'qmake-qt4' }
  install { sudo 'cp bin/phantomjs /usr/local/bin/' }
  requires 'qt-dev.managed'
end

dep 'qt-dev.managed' do
  installs {
    on :apt, 'libqt4-dev', 'libqtwebkit-dev', 'qt4-qmake'
  }
  provides []
end

dep 'postgresql-contrib.managed' do
  provides []
end

dep 'tidy.managed' do
  provides 'tidy'
end
