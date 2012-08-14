  requires 'delayed_job.upstart'.with(env)
end

dep 'delayed_job.upstart', :env do
  respawn 'true'
  command "bundle exec rake jobs:work RAILS_ENV=#{env}"
  setuid shell('whoami')
  chdir "/srv/http/#{user}/current"
  met? {
    !shell("ps aux").split("\n").grep(/rake jobs:work RAILS_ENV=#{env}$/).empty?
  }
end
