meta :push do
  def repo
    @repo ||= Babushka::GitRepo.new('.')
  end
  def self.remote_host_and_path remote
    @remote_host_and_path ||= shell("git config remote.#{remote}.url").split(':', 2)
  end
  def self.remote_head remote
    host, path = remote_host_and_path(remote)
    @remote_head ||= shell!("ssh #{host} 'cd #{path} && git rev-parse --short=7 HEAD 2>/dev/null || echo 0000000'")
  end
  def remote_host; self.class.remote_host_and_path(remote).first end
  def remote_path; self.class.remote_host_and_path(remote).last end
  def remote_head; self.class.remote_head(remote) end
  def self.uncache!
    @remote_head = nil
    @remote_host_and_path = nil
  end
  def git_log from, to
    if from[/^0+$/]
      log "Starting #{remote} at #{to[0...7]} (a #{shell("git rev-list #{to} | wc -l").strip}-commit history) since the repo is blank."
    else
      log shell("git log --graph --date-order --pretty='format:%C(yellow)%h%Cblue%d%Creset %s %C(white) %an, %ar%Creset' #{from}..#{to}")
    end
  end
end
