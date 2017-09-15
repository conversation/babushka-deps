dep 'docker.bin', :version do
  version.default!('17.06.2-ce')

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
  version.default!('1.15.0')
  met? {
    in_path? "docker-compose >= #{version}"
  }
  meet {
    shell "curl -L https://github.com/docker/compose/releases/download/1.15.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose"
    shell "chmod a+x /usr/local/bin/docker-compose"
  }
end

dep 'docker-gc' do
  def docker_gc_src; "docker/docker-gc.erb" end
  def docker_gc_dest; "/etc/cron.hourly/docker-gc" end
  def docker_gc_exclude_src; "docker/docker-gc-exclude.erb" end
  def docker_gc_exclude_dest; "/etc/docker-gc-exclude" end

  def up_to_date?(source_name, dest)
    source = dependency.load_path.parent / source_name
    Babushka::Renderable.new(dest).from?(source) && Babushka::Renderable.new(dest).clean?
  end

  met? {
    up_to_date?(docker_gc_src, docker_gc_dest) &&
    up_to_date?(docker_gc_exclude_src, docker_gc_exclude_dest)
  }

  meet {
    render_erb(docker_gc_src, to: docker_gc_dest)
    render_erb(docker_gc_exclude_src, to: docker_gc_exclude_dest)
  }

  after {
    shell "chmod a+x #{docker_gc_dest}"
  }
end
