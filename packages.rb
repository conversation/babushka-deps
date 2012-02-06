dep 'bundler.gem' do
  provides 'bundle'
end

dep 'libxml.managed' do
  installs { via :apt, 'libxml2-dev' }
  provides []
end

dep 'libxslt.managed' do
  installs { via :apt, 'libxslt1-dev' }
  provides []
end

dep 'imagemagick.managed' do
  provides %w[compare animate convert composite conjure import identify stream display montage mogrify]
end

dep 'coffeescript.src', :version do
  version.default!('1.1.2')
  requires 'nodejs.src'
  source "http://github.com/jashkenas/coffee-script/tarball/#{version}"
  provides 'coffee'

  configure { true }
  build { shell "bin/cake build" }
  install { shell "bin/cake install", :sudo => Babushka::SrcHelper.should_sudo? }
end

dep 'nodejs.src', :version do
  version.default!('0.4.12')
  source "http://nodejs.org/dist/node-v#{version}.tar.gz"
  provides 'node', 'node-waf'
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
