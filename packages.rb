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
  install { shell "bin/cake install", sudo: Babushka::SrcHelper.should_sudo? }
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

dep 'phantomjs.managed' do
  requires { 
    on :apt, 'etienne.ppa'
  }
end

dep 'etienne.ppa' do
  adds 'ppa:jerome-etienne/neoip'
end

dep 'postgresql-contrib.managed' do
  provides []
end

dep 'tidy.managed' do
  provides 'tidy'
end
