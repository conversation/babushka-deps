dep "git remote", :remote_name, :user, :host do
  def remote_spec
    "#{user}@#{host}:~/current"
  end

  def remote_command
    shell("git remote").include?(remote_name.to_s) ? "set-url" : "add"
  end

  met? do
    shell("git remote -v").split("\n").grep(
      /^#{Regexp.escape(remote_name)}\s+#{Regexp.escape(remote_spec)}\s+\(push\)$/
    ).any?
  end

  meet do
    shell "git remote #{remote_command} #{remote_name} '#{remote_spec}'"
  end
end
