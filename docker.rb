dep "docker.bin", :version do
  version.default!("17.09.1-ce")

  requires [
    "docker config",
    "docker credentials"
  ]

  requires_when_unmet do
    on :apt, "keyed apt source".with(
      uri: "https://download.docker.com/linux/ubuntu",
      release: "xenial",
      repo: "stable",
      key_sig: "0EBFCD88",
      key_uri: "https://download.docker.com/linux/ubuntu/gpg"
    )
  end

  installs do
    via :apt, "docker-ce"
    via :brew, "docker"
  end

  provides "docker >= #{version}"
end

dep "docker config" do
  def docker_config
    "/root/.docker/config.json"
  end

  met? { docker_config.p.exists? }

  meet do
    shell "mkdir -p /root/.docker"
    shell %(echo '{"credsStore": "ecr-login"}' > #{docker_config})
    shell "chmod 600 #{docker_config}"
  end
end

dep "docker-compose", :version do
  version.default!("1.16.1")
  met? do
    in_path? "docker-compose >= #{version}"
  end
  meet do
    shell "curl -L https://github.com/docker/compose/releases/download/1.15.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose"
    shell "chmod a+x /usr/local/bin/docker-compose"
  end
end

dep "docker-gc" do
  def docker_gc_src
    "docker/docker-gc.erb"
  end

  def docker_gc_dest
    "/etc/cron.hourly/docker-gc"
  end

  def docker_gc_exclude_src
    "docker/docker-gc-exclude.erb"
  end

  def docker_gc_exclude_dest
    "/etc/docker-gc-exclude"
  end

  def up_to_date?(source_name, dest)
    source = dependency.load_path.parent / source_name
    Babushka::Renderable.new(dest).from?(source) && Babushka::Renderable.new(dest).clean?
  end

  met? do
    up_to_date?(docker_gc_src, docker_gc_dest) &&
    up_to_date?(docker_gc_exclude_src, docker_gc_exclude_dest)
  end

  meet do
    render_erb(docker_gc_src, to: docker_gc_dest)
    render_erb(docker_gc_exclude_src, to: docker_gc_exclude_dest)
  end

  after do
    shell "chmod a+x #{docker_gc_dest}"
  end
end

dep "docker credentials" do
  met? { in_path? "docker-credential-ecr-login" }

  meet do
    shell "curl -L https://github.com/lox/amazon-ecr-credential-helper/releases/download/v1.0.0/docker-credential-ecr-login_linux_amd64 > /usr/local/bin/docker-credential-ecr-login"
    shell "chmod a+x /usr/local/bin/docker-credential-ecr-login"
  end
end
