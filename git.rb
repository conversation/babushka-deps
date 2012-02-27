dep 'git remote', :remote_name, :user, :host do
  def remote_spec
    "#{user}@#{host}:~/current"
  end
  met? {
    shell("git remote -v").split("\n").grep(
      /^#{Regexp.escape(remote_name)}\s+#{Regexp.escape(remote_spec)}\s+\(push\)$/
    ).any?
  }
  meet {
    shell "git remote add #{remote_name} '#{remote_spec}'"
  }
end
