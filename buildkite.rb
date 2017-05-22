dep 'buildkite-agent.bin', :version do
  def enable_agent
    log_shell "Enabling buildkite agent...", "systemctl enable buildkite-agent", sudo: true
  end

  def start_agent
    log_shell "Starting buildkite agent...", "systemctl start buildkite-agent", sudo: true
  end

  version.default!('9.6.3')

  requires_when_unmet {
    on :apt, 'keyed apt source'.with(
      :uri => 'https://apt.buildkite.com/buildkite-agent',
      :release => 'stable',
      :repo => 'main',
      :key_sig => '6452D198'
    )
  }

  installs {
    via :apt, "buildkite-agent"
  }

  after {
    enable_agent
    start_agent
  }

  provides "buildkite-agent >= #{version}"
end
