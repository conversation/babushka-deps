dep "buildkite-agent.bin", :version do
  version.default!("2.6.3")

  requires_when_unmet {
    on :apt, "keyed apt source".with(
      :uri => "https://apt.buildkite.com/buildkite-agent",
      :release => "stable",
      :repo => "main",
      :key_sig => "6452D198"
    )
  }

  installs {
    via :apt, "buildkite-agent"
  }

  after {
    log_shell "Enabling buildkite agent...", "systemctl enable buildkite-agent", sudo: true
    log_shell "Starting buildkite agent...", "systemctl start buildkite-agent", sudo: true
  }

  provides "buildkite-agent >= #{version}"
end

dep "buildkite token installed", :buildkite_token do
  met? { "/etc/buildkite-agent/buildkite-agent.cfg".p.grep(/#{buildkite_token}/) }
  meet { sudo %Q(sed -i "s/xxx/#{buildkite_token}/g" /etc/buildkite-agent/buildkite-agent.cfg) }
end
