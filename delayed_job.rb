dep 'delayed job', :env, :user do
  requires 'delayed_job.upstart'.with(env, user)
end

dep 'delayed_job.upstart', :env, :user do
  respawn 'true'
  command "bundle exec rake jobs:work RAILS_ENV=#{env}"
  setuid user
  chdir "/srv/http/#{user}/current"
  met? {
    !shell("ps aux").split("\n").grep(/rake jobs:work RAILS_ENV=#{env}$/).empty?
  }
end
