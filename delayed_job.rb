dep "delayed job", :env, :user, :queue do
  requires "delayed_job.systemd".with(env, user, queue)
end

dep "delayed_job.systemd", :env, :user, :queue do
  description "Delayed job worker"
  respawn "yes"

  queue.default "global"

  vars = ["RACK_ENV=#{env}", "RAILS_ENV=#{env}"]

  unless queue[/global/]
    suffix "#{queue}_queue"
    vars << "QUEUES=#{queue}"
  end

  command "/usr/local/bin/bundle exec rake jobs:work #{vars.join(' ')}"
  setuid user
  chdir "/srv/http/#{user}/current"

  met? do
    shell?("ps u -u #{user} | grep -v grep | grep 'rake jobs:work #{vars.join(' ')}'")
  end
end

dep "delayed job restarted", template: "task" do
  run do
    output = shell?('ps ux | grep -v grep | grep "rake jobs:work"')

    if output.nil?
      log "`rake jobs:work` isn't running."
      true
    else
      pids = output.scan(/^\S+\s+(\d+)\s+/).flatten
      pids.each do |pid|
        log_shell "Sending SIGTERM to #{pid}", "kill -s TERM #{pid}"
      end
    end
  end
end
