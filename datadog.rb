dep "datadog agent installed", :datadog_api_key, :datadog_postgres_password do
  requires [
    "datadog-agent.bin",
    "stats endpoint configured.nginx",
    "datadog configured".with(datadog_api_key: datadog_api_key, datadog_postgres_password: datadog_postgres_password)
  ]

  met? do
    shell? "systemctl status datadog-agent"
  end

  meet do
    log_shell "starting datadog-agent", "systemctl restart datadog-agent"
  end
end

dep "datadog-agent.bin", :version do
  version.default!("6.0")

  requires [
    "apt-transport-https.bin",
    "datadog apt key installed",
  ]

  requires_when_unmet do
    on :apt, "apt source".with(
      uri: "https://apt.datadoghq.com/",
      uri_matcher: "https://apt.datadoghq.com/",
      release: "stable",
      repo: "6",
    )
  end

  installs do
    via :apt, "datadog-agent"
  end

  provides "datadog-agent"
end

dep "datadog configured", :datadog_api_key, :datadog_postgres_password do
  def datadog_src
    "datadog/datadog.yaml.erb".p
  end

  def datadog_dest
    "/etc/datadog-agent/datadog.yaml".p
  end

  def docker_src
    "datadog/docker.yaml".p
  end

  def docker_dest
    "/etc/datadog-agent/conf.d/docker.d/conf.yaml".p
  end

  def nginx_src
    "datadog/nginx.yaml".p
  end

  def nginx_dest
    "/etc/datadog-agent/conf.d/nginx.d/conf.yaml".p
  end

  def postgres_src
    "datadog/postgres.yaml.erb".p
  end

  def postgres_dest
    "/etc/datadog-agent/conf.d/postgres.d/conf.yaml".p
  end

  def up_to_date?(source, dest)
    Babushka::Renderable.new(dest).from?(source) && Babushka::Renderable.new(dest).clean?
  end

  met? do
    up_to_date?(datadog_src, datadog_dest) &&
    docker_dest.exists? &&
    nginx_dest.exists? &&
    up_to_date?(postgres_src, postgres_dest)
  end

  meet do
    render_erb datadog_src, to: datadog_dest, sudo: true
    sudo "cp #{docker_src.abs} #{docker_dest.abs}"
    sudo "cp #{nginx_src.abs} #{nginx_dest.abs}"
    render_erb postgres_src, to: postgres_dest, sudo: true
  end
end

dep "datadog apt key installed" do
  met? { shell("apt-key list").split("\n").collapse(/^pub.*\//).val_for("382E94DE") }
  meet { sudo("apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 382E94DE") }
end
