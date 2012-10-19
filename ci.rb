dep 'ci prepared', :app_user, :public_key, :private_key do
  requires [
    'benhoskings:passwordless ssh logins'.with(:username => 'root', :key => public_key),
    'benhoskings:passwordless ssh logins'.with(:username => app_user, :key => public_key),
    'conversation:key installed'.with(:username => app_user, :public_key => public_key, :private_key => private_key),

    'benhoskings:set.locale'.with(:locale_name => 'en_AU'),
    'benhoskings:ruby.src'.with(:version => '1.9.3', :patchlevel => 'p194'),
  ]
end

dep 'ci provisioned', :app_user, :public_key, :private_key do
  requires [
    'ci prepared'.with(app_user, public_key, private_key),
    'benhoskings:utc',
    'conversation:localhost hosts entry',
    'benhoskings:lax host key checking',
    'conversation:apt sources',
    'conversation:theconversation.edu.au common packages',
    'conversation:sharejs.theconversation.edu.au common packages',
    'conversation:counter.theconversation.edu.au common packages',
    'conversation:ci packages',
    'benhoskings:postgres access'.with(:username => app_user, :flags => '-sdrw'),
    'conversation:jenkins target'.with(:app_user => app_user)
  ]
end

dep 'ci packages' do
  requires [
    'openjdk-6-jdk',
    'selenium runtime',
    'phantomjs'
  ]
end

dep 'openjdk-6-jdk', :template => 'bin' do
  provides 'java', 'javac'
end

dep 'key installed', :username, :public_key, :private_key do
  def ssh_dir
    "~#{username}/.ssh/".p
  end
  met? {
    # TODO: This is only a partial check, but it'll do for now.
    (ssh_dir / 'ci_host').exists? && (ssh_dir / 'ci_host').read['PRIVATE KEY']
  }
  meet {
    (ssh_dir / 'ci_host.pub').write(public_key)
    (ssh_dir / 'ci_host').write(private_key)
    (ssh_dir / 'config').append "IdentityFile ~/.ssh/ci_host\n"
  }
end

dep 'jenkins target', :path, :app_user do
  path.default!('/opt/jenkins')
  met? {
    path.p.directory? && shell?("touch #{path}", :as => app_user)
  }
  meet {
    path.p.mkdir
    shell "chown -R #{app_user}:#{app_user} #{path}"
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

dep 'phantomjs' do
  met? {
    in_path? 'phantomjs'
  }
  meet {
    Babushka::Resource.extract "http://phantomjs.googlecode.com/files/phantomjs-1.5.0-linux-x86_64-dynamic.tar.gz" do |archive|
      shell "cp -r . /usr/local/phantomjs"
      shell "ln -fs /usr/local/phantomjs/bin/phantomjs /usr/local/bin"
    end
  }
end
