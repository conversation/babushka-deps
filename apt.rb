dep "our apt source" do
  requires "apt source".with(uri: "http://apt.tc-dev.net/", repo: "main")
  requires "gpg key".with("B6D8A3F9")
end

dep "apt sources", for: :ubuntu do
  met? do
    Babushka::Renderable.new("/etc/apt/sources.list").from?(dependency.load_path.parent / "apt/sources.list.erb")
  end
  meet do
    render_erb "apt/sources.list.erb", to: "/etc/apt/sources.list"
    shell "rm -f /etc/apt/sources.list.d/babushka.list"
    Babushka::AptHelper.update_pkg_lists "Updating apt lists with our new config"
  end
end

dep "upgrade apt packages", template: "task" do
  requires "aptitude.bin"
  run do
    log_shell("Upgrading installed packages", "#{Babushka::AptHelper.pkg_cmd} -y full-upgrade")
  end
end

dep "apt packages removed", :packages, for: :apt do
  def installed_packages
    shell("dpkg --get-selections").split("\n").select {|l|
      l[/\binstall$/]
    }.map do |l|
      l.split(/\s+/, 2).first
    end
  end

  def to_remove(packages)
    # This is required because babushka parameters aren't enumerable yet.
    package_list = packages.to_a
    installed_packages.select do |installed_package|
      package_list.any? {|p| installed_package[p] }
    end
  end
  met? do
    to_remove(packages).empty?
  end
  meet do
    to_remove(packages).each do |pkg|
      log_shell "Removing #{pkg}", "apt-get -y remove --purge '#{pkg}'", sudo: true
    end
  end
  after do
    log_shell "Autoremoving packages", "apt-get -y autoremove", sudo: true
  end
end
