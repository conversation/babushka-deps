dep 'provision ci', :keys, :host, :user, :buildkite_token do
  keys.default!((dependency.load_path.parent / 'config/authorized_keys').read)
  user.default!("buildkite-agent")

  requires_when_unmet 'public key in place'.with(host, keys)
  requires_when_unmet 'babushka bootstrapped'.with(host)

  met? { false }
  meet do
    ssh("root@#{host}") do |h|
      h.babushka(
        "conversation:ci provisioned",
        keys: keys,
        user: user,
        buildkite_token: buildkite_token
      )
    end
  end
end

dep 'ci prepared' do
  requires [
    'common:set.locale'.with(:locale_name => 'en_AU'),
    'ruby.src'.with(:version => '2.3.3', :patchlevel => 'p222'),
  ]
end

dep 'ci provisioned', :user, :keys, :buildkite_token do
  requires [
    'ci prepared',
    'localhost hosts entry',
    'lax host key checking',
    'tc common packages',
    'sharejs common packages',
    'counter common packages',
    'jobs common packages',
    'ci packages',
    'firewall rules',
    'buildkite-agent installed'.with(buildkite_token: buildkite_token),
    'postgres access'.with(:username => user, :flags => '-sdrw'),
    'docker-gc'
  ]
end

dep 'ci packages' do
  requires [
    'ack-grep.bin',
    'silversearcher.bin',
    'docker.bin',
    'docker-compose',
    'firefox.bin',
    'phantomjs',
    'python.bin',
    'redis-server.bin',
    'sasl.lib',
    'terraform',
    'tmux.bin',
    'ufw.bin',
    'xvfb.bin'
  ]
end

dep 'firewall rules' do
  met? {
    shell? %q(ufw status | grep "Status: active")
  }

  meet {
    shell "ufw allow ssh/tcp"
    shell "ufw --force enable"
  }
end

dep 'phantomjs', :version do
  version.default!('2.1.1')
  def phantomjs_uri
    if Babushka.host.linux?
      "https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-#{version}-linux-x86_64.tar.bz2"
    elsif Babushka.host.osx?
      "https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-#{version}-macosx.zip"
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

dep 'ack-grep.bin' do
  provides 'ack'
end

dep 'python.bin' do
  provides 'python'
end

dep 'xvfb.bin' do
  provides 'Xvfb'
end

dep 'firefox.bin'

dep 'terraform', :version do
  version.default!('0.9.5')
  met? {
    in_path? "terraform >= #{version}"
  }
  meet {
    Babushka::Resource.extract "https://releases.hashicorp.com/terraform/0.9.5/terraform_0.9.5_linux_amd64.zip" do |archive|
      shell "cp -r terraform /usr/local/bin/terraform"
    end
  }
end

dep 'ufw.bin'
