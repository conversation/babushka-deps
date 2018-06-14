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
  met? do
    "/etc/datadog-agent/datadog.yaml".p.grep(/^api_key: #{datadog_api_key}/) &&
    "/etc/datadog-agent/datadog.yaml".p.grep(/^use_dogstatsd: yes/) &&
    "/etc/datadog-agent/datadog.yaml".p.grep(/^dogstatsd_port: 8126/)
  end

  meet do
    sudo %W[
      sed
      -e 's/api_key:.*/api_key: #{datadog_api_key}/'
      -e 's/# use_dogstatsd:.*/use_dogstatsd: yes/'
      -e 's/# dogstatsd_port:.*/dogstatsd_port: 8126/'
      /etc/datadog-agent/datadog.yaml.example > /etc/datadog-agent/datadog.yaml
    ].join(" ")
  end
end

dep "datadog apt key installed" do
  met? { shell("apt-key list").split("\n").collapse(/^pub.*\//).val_for("382E94DE") }
  meet { sudo("apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 382E94DE") }
end
