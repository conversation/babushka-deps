dep "datadog agent installed", :datadog_api_key do
  requires [
    "datadog-agent.bin",
    "datadog api key installed".with(datadog_api_key: datadog_api_key)
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

dep "datadog api key installed", :datadog_api_key do
  met? { "/etc/datadog-agent/datadog.yaml".p.grep(/#{datadog_api_key}/) }
  meet { sudo %Q(sed 's/api_key:.*/api_key: #{datadog_api_key}/' /etc/datadog-agent/datadog.yaml.example > /etc/datadog-agent/datadog.yaml) }
end

dep "datadog apt key installed" do
  met? { shell("apt-key list").split("\n").collapse(/^pub.*\//).val_for("382E94DE") }
  meet { sudo("apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 382E94DE") }
end
