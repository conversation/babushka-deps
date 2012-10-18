dep 'ci prepared', :app_user, :ssh_key do
  requires [
    'benhoskings:passwordless ssh logins'.with(:username => 'root', :key => ssh_key),
    'benhoskings:passwordless ssh logins'.with(:username => app_user, :key => ssh_key),

    'benhoskings:set.locale'.with(:locale_name => 'en_AU'),
    'benhoskings:ruby.src'.with(:version => '1.9.3', :patchlevel => 'p194'),
  ]
end

dep 'ci provisioned', :app_user, :ssh_key do
  requires [
    'ci prepared'.with(app_user, ssh_key),
    'benhoskings:utc',
    'conversation:localhost hosts entry',
    'conversation:apt sources',
    'conversation:theconversation.edu.au common packages',
    'conversation:counter.theconversation.edu.au common packages',
    'conversation:ci packages',
    'benhoskings:postgres access',
    'conversation:jenkins target'.with(:app_user => app_user)
  ]
end

dep 'ci packages' do
  requires [
    'openjdk-6-jdk',
    'selenium runtime'
  ]
end

dep 'openjdk-6-jdk', :template => 'bin' do
  provides 'java', 'javac'
end

dep 'jenkins target', :path, :app_user do
  path.default!('/opt/jenkins')
  met? {
    path.p.directory? && shell?("touch #{path}", :as => app_user)
  }
  meet {
    path.p.mkdir
    shell "chown -R #{app_user} #{path}"
  }
end

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
