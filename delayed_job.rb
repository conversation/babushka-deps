dep 'delayed job' do
  requires 'delayed_job.supervisor'
end

dep 'delayed_job.supervisor' do
  restart 'always'
  command "bundle exec rake jobs:work RAILS_ENV=production"
  user "theconversation.edu.au"
  directory "/srv/http/#{user}/current"
  met? {
    !shell("ps aux").split("\n").grep(/rake jobs:work$/).empty?
  }
end

dep 'delayed job restarted.task' do
  run {
    output = shell('ps aux | grep "rake jobs:work" | grep -v grep')

    if output.nil?
      log_error "`rake jobs:work` isn't running."
    else
      shell "kill -s TERM #{output.scan(/^\w+\s+(\d+)\s+/).flatten.first}"
    end
  }
end
