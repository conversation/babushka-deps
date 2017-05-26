dep 'docker.bin', :version do
  version.default!('17.03.1-ce')

  requires_when_unmet {
    on :apt, 'keyed apt source'.with(
      :uri => 'https://download.docker.com/linux/ubuntu',
      :release => 'xenial',
      :repo => 'stable',
      :key_sig => '0EBFCD88',
      :key_uri => 'https://download.docker.com/linux/ubuntu/gpg'
    )
  }

  installs {
    via :apt, "docker-ce"
    via :brew, "docker"
  }

  provides "docker >= #{version}"
end

dep 'docker-compose', :version do
  version.default!('1.13.0')
  met? {
    in_path? "docker-compose >= #{version}"
  }
  meet {
    shell "curl -L https://github.com/docker/compose/releases/download/1.13.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose"
    shell "chmod a+x /usr/local/bin/docker-compose"
  }
end
