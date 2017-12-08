dep "passwordless sudo", :username do
  setup do
    unmeetable! "This dep must be run as root." unless shell("whoami") == "root"
  end
  met? do
    shell "sudo -k", as: username # expire an existing cached password
    shell? "sudo -n true", as: username
  end
  meet do
    shell "echo '#{username} ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers"
  end
end

dep "passwordless sudo removed" do
  setup do
    unmeetable! "This dep must be run as root." unless shell("whoami") == "root"
  end
  met? do
    raw_shell("grep NOPASSWD /etc/sudoers").stdout.empty?
  end
  meet do
    shell "sed -i'' -e '/NOPASSWD/d' /etc/sudoers"
  end
end
