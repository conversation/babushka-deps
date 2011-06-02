meta :cronjob do
  accepts_value_for :timing
  accepts_value_for :command
  def entry
    "#{timing} #{command}"
  end
  template {
    met? {
      output = failable_shell('crontab -l').stdout
      if output.include?(entry)
        true
      elsif output.split("\n").detect {|l| l.ends_with?(command) }
        met "The job is scheduled, but with different timing."
      end
    }
    meet {
      shell 'crontab -', input: [shell('crontab -l'), entry].compact.join("\n").end_with("\n")
    }
  }
end

dep 'cronjobs' do
  requires 'hourly.cronjob', 'daily.cronjob', 'weekly.cronjob'
end

dep 'hourly.cronjob' do
  timing '18 * * * *'
  command "cd #{'~/current'.p} && RAILS_ENV=production ./script/tasks/hourly >> log/tasks.log"
end

dep 'daily.cronjob' do
  # hour 15 is 3pm UTC, which is 1am GMT+10.
  timing '33 15 * * *'
  command "cd #{'~/current'.p} && RAILS_ENV=production ./script/tasks/daily >> log/tasks.log"
end

dep 'weekly.cronjob' do
  timing '48 15 * * 7'
  command "cd #{'~/current'.p} && RAILS_ENV=production ./script/tasks/weekly >> log/tasks.log"
end
