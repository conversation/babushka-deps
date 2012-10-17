dep 'selenium runtime', :template => 'lib' do
  installs [
    'xvfb',
    'xserver-xorg-core',
    'xfonts-100dpi',
    'xfonts-75dpi',
    'xfonts-scalable',
    'xfonts-cyrillic',
    'firefox',
    'libqt4-dev'
  ]
end
