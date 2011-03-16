dep 'packages' do
  requires [
    'libxml.managed', # for nokogiri
    'libxslt.managed',  # for nokogiri
    'imagemagick.managed', # for paperclip
    'coffeescript.src' # for barista
    'supervisor.managed'
  ]
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

dep 'coffeescript.src' do
  requires 'nodejs.src'
  source 'git://github.com/jashkenas/coffee-script.git'
  provides 'coffee'

  configure { true }
  build { shell "bin/cake build" }
  install { shell "bin/cake install", sudo: Babushka::SrcHelper.should_sudo? }
end

dep 'nodejs.src' do
  source 'git://github.com/joyent/node.git'
  provides 'node', 'node-waf'
end

dep 'rsync.managed'

dep 'supervisor.managed' do
  provides 'supervisord', 'supervisorctl'
end
