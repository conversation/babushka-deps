dep "buildkite-agent installed", :buildkite_token do
  requires [
    "buildkite-agent.bin",
    "buildkite ssh key installed",
    "buildkite token installed".with(buildkite_token: buildkite_token)
  ]
end

dep "buildkite-agent.bin", :version do
  version.default!("3.0-beta.27")

  requires "buildkite apt key installed"

  requires_when_unmet do
    on :apt, "apt source".with(
      uri: "https://apt.buildkite.com/buildkite-agent",
      uri_matcher: "https://apt.buildkite.com/buildkite-agent",
      release: "unstable",
      repo: "main"
    )
  end

  installs do
    via :apt, "buildkite-agent"
  end

  after do
    log_shell "Adding buildkite agent to docker group...", "usermod -aG docker buildkite-agent", sudo: true
    log_shell "Enabling buildkite agent...", "systemctl enable buildkite-agent", sudo: true
    log_shell "Starting buildkite agent...", "systemctl start buildkite-agent", sudo: true
  end

  provides "buildkite-agent >= #{version}"
end

dep "buildkite ssh key installed" do
  met? { "/var/lib/buildkite-agent/.ssh/id_rsa.pub".p.exists? }

  meet do
    sudo %Q(mkdir -p ~/.ssh && cd ~/.ssh & ssh-keygen -t rsa -b 4096 -C "$(hostname)" -f ~/.ssh/id_rsa -N ""), as: "buildkite-agent", su: true
  end
end

dep "buildkite apt key installed" do
  met? do
    shell("apt-key list").split("\n").collapse(/^pub.*\//).val_for("6452D198")
  end

  meet do
    sudo %Q(apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 32A37959C2FA5C3C99EFBC32A79206696452D198)
  end
end

dep "buildkite token installed", :buildkite_token do
  met? { "/etc/buildkite-agent/buildkite-agent.cfg".p.grep(/#{buildkite_token}/) }
  meet { sudo %Q(sed -i "s/xxx/#{buildkite_token}/g" /etc/buildkite-agent/buildkite-agent.cfg) }
end
