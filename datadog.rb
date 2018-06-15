dep "datadog agent installed", :datadog_api_key do
  requires [
    "datadog-agent.bin",
    "stats endpoint configured.nginx",
    "datadog configured".with(datadog_api_key: datadog_api_key)
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

dep "datadog configured", :datadog_api_key do
  def datadog_src
    "datadog/datadog.yaml.erb".p
  end

  def datadog_dest
    "/etc/datadog-agent/datadog.yaml".p
  end

  def nginx_src
    "datadog/nginx.yaml".p
  end

  def nginx_dest
    "/etc/datadog-agent/conf.d/nginx.d/conf.yaml".p
  end

  def up_to_date?(source, dest)
    Babushka::Renderable.new(dest).from?(source) && Babushka::Renderable.new(dest).clean?
  end

  met? do
    up_to_date?(datadog_src, datadog_dest) &&
    nginx_dest.exists?
  end

  meet do
    render_erb datadog_src, to: datadog_dest, sudo: true
    sudo "cp #{nginx_src.abs} #{nginx_dest.abs}"
  end
end

dep "datadog apt key installed" do
  met? { shell("apt-key list").split("\n").collapse(/^pub.*\//).val_for("382E94DE") }
  meet { sudo("apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 382E94DE") }
end
