dep "zsh", :username do
  username.default!(shell("whoami"))
  requires "zsh available"

  # It would be great to be able to do this, but GNU `login` doesn't have '-f'.
  # met? { shell("login -f '#{username}' env").val_for('SHELL') == which('zsh') }
  met? { shell("sudo su - '#{username}' -c 'echo $SHELL'") == which("zsh") }
  meet { sudo("chsh -s '#{which('zsh')}' #{username}") }
end

dep "zsh available" do
  requires "zsh.bin"

  met? { "/etc/shells".p.grep(which("zsh")) }
  meet { append_to_file which("zsh"), "/etc/shells", sudo: true }
end

dep "zsh.bin"
