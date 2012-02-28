meta :cronjob do
  accepts_value_for :timing
  accepts_value_for :command
  def entry
    "#{timing} #{command}"
  end
  template {
    met? {
      output = raw_shell('crontab -l').stdout
      if output.include?(entry)
        true
      elsif output.split("\n").detect {|l| l.ends_with?(command) }
        # Don't add the same job to the crontab a second time.
        met "The job is scheduled, but with different timing."
      end
    }
    meet {
      shell 'crontab -', :input => [shell('crontab -l'), entry].compact.join("\n").end_with("\n")
    }
  }
end

dep 'cronjobs', :env do
  requires 'hourly.cronjob'.with(env), 'daily.cronjob'.with(env), 'weekly.cronjob'.with(env)
end

dep 'minutely.cronjob', :env do
  timing '* * * * *'
  command "cd #{'~/current'.p} && RAILS_ENV=#{env} ./script/tasks/minutely >> log/tasks.log"
end

dep 'hourly.cronjob', :env do
  timing '18 * * * *'
  command "cd #{'~/current'.p} && RAILS_ENV=#{env} ./script/tasks/hourly >> log/tasks.log"
end

dep 'daily.cronjob', :env do
  # hour 15 is 3pm UTC, which is 1am GMT+10.
  timing '33 15 * * *'
  command "cd #{'~/current'.p} && RAILS_ENV=#{env} ./script/tasks/daily >> log/tasks.log"
end

dep 'weekly.cronjob', :env do
  timing '48 15 * * 7'
  command "cd #{'~/current'.p} && RAILS_ENV=#{env} ./script/tasks/weekly >> log/tasks.log"
end
