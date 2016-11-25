dep 'delayed job', :env, :user do
  requires 'delayed_job.upstart'.with(env, user)
end

dep 'delayed_job.upstart', :env, :user do
  respawn 'yes'
  # This command includes both RACK_ENV and RAILS_ENV as this upstart config can
  # be used for rails and non-rails apps.
  command "bundle exec rake jobs:work RACK_ENV=#{env} RAILS_ENV=#{env}"
  setuid user
  chdir "/srv/http/#{user}/current"
  met? {
    shell?("ps ux | grep -v grep | grep 'rake jobs:work'")
  }
end
