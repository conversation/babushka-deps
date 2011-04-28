dep 'crontab' do
  setup {
    @hour = 11 # 1am in GMT+10
    @min = rand(60)
  }
  met? {
    babushka_config? "/etc/crontab"
  }
  meet {
    render_erb "utils/crontab.erb", :to => "/etc/crontab", :sudo => true
  }
end

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
  command "cd #{'~/current'.p} && ./script/tasks/hourly >> log/tasks.log"
end

dep 'daily.cronjob' do
  # hour 11 is 1am in GMT+10.
  timing '33 11 * * *'
  command "cd #{'~/current'.p} && ./script/tasks/daily >> log/tasks.log"
end

dep 'weekly.cronjob' do
  timing '48 11 * * 7'
  command "cd #{'~/current'.p} && ./script/tasks/weekly >> log/tasks.log"
end
