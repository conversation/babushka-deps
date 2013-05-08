dep 'our apt source' do
  requires 'apt source'.with(:uri => 'http://apt.tc-dev.net/', :repo => 'main')
  requires 'gpg key'.with('B6D8A3F9')
end

dep 'apt sources', :for => :ubuntu do
  met? {
    Babushka::Renderable.new("/etc/apt/sources.list").from?(dependency.load_path.parent / "apt/sources.list.erb")
  }
  meet {
    render_erb "apt/sources.list.erb", :to => "/etc/apt/sources.list"
    shell "rm -f /etc/apt/sources.list.d/babushka.list"
    Babushka::AptHelper.update_pkg_lists "Updating apt lists with our new config"
  }
end

dep 'apt packages removed', :packages, :for => :apt do
  def installed_packages
    shell("dpkg --get-selections").split("\n").select {|l|
      l[/\binstall$/]
    }.map {|l|
      l.split(/\s+/, 2).first
    }
  end
  def to_remove packages
    # This is required because babushka parameters aren't enumerable yet.
    package_list = packages.to_a
    installed_packages.select {|installed_package|
      package_list.any? {|p| installed_package[p] }
    }
  end
  met? {
    to_remove(packages).empty?
  }
  meet {
    to_remove(packages).each {|pkg|
      log_shell "Removing #{pkg}", "apt-get -y remove --purge '#{pkg}'", :sudo => true
    }
  }
  after {
    log_shell "Autoremoving packages", "apt-get -y autoremove", :sudo => true
  }
end
