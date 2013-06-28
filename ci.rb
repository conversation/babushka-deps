dep 'ci prepared', :app_user, :public_key, :private_key do
  requires [
    'passwordless ssh logins'.with(:username => 'root', :key => public_key),
    'passwordless ssh logins'.with(:username => app_user, :key => public_key),
    'key installed'.with(:username => app_user, :public_key => public_key, :private_key => private_key),

    'set.locale'.with(:locale_name => 'en_AU'),
    'ruby.src'.with(:version => '2.0.0', :patchlevel => 'p247'),
  ]
end

dep 'ci provisioned', :app_user, :public_key, :private_key do
  requires [
    'ci prepared'.with(app_user, public_key, private_key),
    'localhost hosts entry',
    'lax host key checking',
    'apt sources',
    'tc common packages',
    'sharejs common packages',
    'counter common packages',
    'jobs common packages',
    'apt packages removed'.with(%w[resolvconf ubuntu-minimal]),
    'ci packages',
    'postgres access'.with(:username => app_user, :flags => '-sdrw'),
    'jenkins target'.with(:app_user => app_user)
  ]
end

dep 'ci packages' do
  requires [
    'openjdk-6-jdk',
    'phantomjs'.with('1.8.2')
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
