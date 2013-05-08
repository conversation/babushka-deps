dep 'localhost hosts entry' do
  met? {
    "/etc/hosts".p.grep(/^127\.0\.0\.1/)
  }
  meet {
    "/etc/hosts".p.append("127.0.0.1 localhost.localdomain localhost\n")
  }
end

dep 'lax host key checking' do
  met? {
    ssh_conf_path(:ssh).p.grep(/^StrictHostKeyChecking[ \t]+no/)
  }
  meet {
    shell("sed -i'' -e 's/^[# ]*StrictHostKeyChecking\\W*\\w*$/StrictHostKeyChecking no/' #{ssh_conf_path(:ssh)}")
  }
end

# It's hard to test for other timezones (EST maps to Australia/Melbourne, etc),
# and we only need UTC right now :)
dep 'utc' do
  met? {
    shell('date')[/\bUTC\b/]
  }
  meet {
    sudo 'echo UTC > /etc/timezone'
    sudo 'dpkg-reconfigure --frontend noninteractive tzdata'
  }
end
