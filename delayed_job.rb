dep 'delayed job', :env do
  requires 'delayed_job.supervisor'.with(env)
end

dep 'delayed_job.supervisor', :env do
  restart 'always'
  command "bundle exec rake jobs:work RAILS_ENV=#{env}"
  user shell('whoami')
  directory "/srv/http/#{user}/current"
  met? {
    !shell("ps aux").split("\n").grep(/rake jobs:work RAILS_ENV=#{env}$/).empty?
  }
end
