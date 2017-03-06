dep 'delayed job', :env, :user, :queue do
  requires 'delayed_job.upstart'.with(env, user, queue)
end

dep 'delayed_job.upstart', :env, :user, :queue do
  respawn 'yes'

  queue.default 'global'

  vars = ["RACK_ENV=#{env}", "RAILS_ENV=#{env}"]

  unless queue[/global/]
    suffix "#{queue}_queue"
    vars << "QUEUES=#{queue}"
  end

  environment vars
  command "bundle exec rake jobs:work"
  setuid user
  chdir "/srv/http/#{user}/current"
  met? {
    shell?("ps ux | grep -v grep | grep 'rake jobs:work'")
  }
end

dep 'delayed job restarted', template: 'task' do
  run {
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
  }
end
