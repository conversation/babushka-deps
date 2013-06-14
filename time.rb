dep 'time is syncronised' do
  requires 'ntpdate.bin'
  met? { "/etc/cron.hourly/ntpdate".p.exists? }
  meet {
    "/etc/cron.hourly/ntpdate".p.write("#!/bin/sh\n# -B - Always skew time\nntpdate -B pool.ntp.org")
    shell "chmod +x /etc/cron.hourly/ntpdate"
  }
end
