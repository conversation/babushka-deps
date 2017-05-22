dep 'provision ci', :keys, :host do
  keys.default!((dependency.load_path.parent / 'config/authorized_keys').read)
  requires_when_unmet 'public key in place'.with(host, keys)
  requires_when_unmet 'babushka bootstrapped'.with(host)
  met? { false }
  meet do
    ssh("root@#{host}") { |h| h.babushka 'conversation:ci provisioned' }
  end
end

dep 'ci prepared' do
  requires [
    'common:set.locale'.with(:locale_name => 'en_AU'),
    'ruby.src'.with(:version => '2.3.3', :patchlevel => 'p222'),
  ]
end

dep 'ci provisioned', :app_user do
  requires [
    'ci prepared',
    'localhost hosts entry',
    'lax host key checking',
    'tc common packages',
    'sharejs common packages',
    'counter common packages',
    'jobs common packages',
    'ci packages',
    'postgres access'.with(:username => app_user, :flags => '-sdrw')
  ]
end

dep 'ci packages' do
  requires [
    'firefox.bin',
    'phantomjs',
    'xvfb.bin'
  ]
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

dep 'xvfb.bin' do
  provides 'Xvfb'
end

dep 'firefox.bin'
