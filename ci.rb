dep 'ci prepared' do
  requires [
    'common:set.locale'.with(:locale_name => 'en_AU'),
    'ruby.src'.with(:version => '2.2.4', :patchlevel => 'p230'),
  ]
end

dep 'ci provisioned', :app_user do
  requires [
    'ci prepared',
    'localhost hosts entry',
    'lax host key checking',
    'apt sources',
    'tc common packages',
    'sharejs common packages',
    'counter common packages',
    'jobs common packages',
    'apt packages removed'.with(%w[resolvconf ubuntu-minimal]),
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
  version.default!('1.8.2')
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
