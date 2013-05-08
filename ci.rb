dep 'ci prepared', :app_user, :public_key, :private_key do
  requires [
    'passwordless ssh logins'.with(:username => 'root', :key => public_key),
    'passwordless ssh logins'.with(:username => app_user, :key => public_key),
    'conversation:key installed'.with(:username => app_user, :public_key => public_key, :private_key => private_key),

    'set.locale'.with(:locale_name => 'en_AU'),
    'benhoskings:ruby.src'.with(:version => '1.9.3', :patchlevel => 'p374'),
  ]
end

dep 'ci provisioned', :app_user, :public_key, :private_key do
  requires [
    'ci prepared'.with(app_user, public_key, private_key),
    'conversation:localhost hosts entry',
    'benhoskings:lax host key checking',
    'conversation:apt sources',
    'conversation:tc common packages',
    'conversation:sharejs common packages',
    'conversation:counter common packages',
    'benhoskings:apt packages removed'.with(/resolvconf|ubuntu\-minimal/i),
    'conversation:ci packages',
    'benhoskings:postgres access'.with(:username => app_user, :flags => '-sdrw'),
    'conversation:jenkins target'.with(:app_user => app_user)
  ]
end

dep 'ci packages' do
  requires [
    'openjdk-6-jdk',
    'phantomjs'.with('1.8.1')
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

    shell "chmod 600 '#{(ssh_dir / 'ci_host')}'"
    sudo "chown -R #{username} '#{ssh_dir}'" unless username == shell('whoami')
  }
end

dep 'jenkins target', :path, :app_user do
  path.default!('/opt/jenkins')
  def app_group
    shell("groups '#{app_user}'").split(' ').first
  end
  met? {
    path.p.directory? && shell?("touch #{path}", :as => app_user)
  }
  meet {
    path.p.mkdir
    shell "chown -R #{app_user}:#{app_group} #{path}"
  }
end

dep 'phantomjs', :version do
  version.default!('1.7.0')
  def phantomjs_uri
    if Babushka.host.linux?
      "https://phantomjs.googlecode.com/files/phantomjs-#{version}-linux-x86_64.tar.bz2"
    elsif Babushka.host.osx?
      "https://phantomjs.googlecode.com/files/phantomjs-#{version}-macosx.zip"
    else
      unmeetable! "Not sure where to download a phantomjs binary for #{Babushka.base.host}."
    end
  end
  met? {
    in_path? "phantomjs >= #{version}"
  }
  meet {
    Babushka::Resource.extract phantomjs_uri do |archive|
      shell "cp -r . /usr/local/phantomjs"
      shell "ln -fs /usr/local/phantomjs/bin/phantomjs /usr/local/bin"
    end
  }
end
