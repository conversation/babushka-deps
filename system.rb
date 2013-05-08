dep 'system', :host_name, :locale_name do
  requires [
    'set.locale'.with(locale_name),
    'core software',
    'hostname'.with(host_name),
    'secured ssh logins',
    'lax host key checking',
    'admins can sudo',
    'tmp cleaning grace period'
  ]
  setup {
    unmeetable! "This dep has to be run as root." unless shell('whoami') == 'root'
  }
end

dep 'core software' do
  requires [
    'sudo.bin',
    'lsof.bin',
    'vim.bin',
    'curl.bin',
    'traceroute.bin',
    'htop.bin',
    'iotop.bin',
    'jnettop.bin',
    'tmux.bin',
    'nmap.bin',
    'tree.bin',
    'pv.bin'
  ]
end

dep 'hostname', :host_name, :for => :linux do
  def current_hostname
    shell('hostname -f')
  end
  host_name.default(shell('hostname'))
  met? {
    current_hostname == host_name
  }
  meet {
    sudo "echo #{host_name} > /etc/hostname"
    sudo "sed -ri 's/^127.0.0.1.*$/127.0.0.1 #{host_name} #{host_name.to_s.sub(/\..*$/, '')} localhost.localdomain localhost/' /etc/hosts"
    sudo "hostname #{host_name}"
  }
end

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

dep 'admins can sudo' do
  requires 'admin group'
  met? {
    !'/etc/sudoers'.p.read.split("\n").grep(/^%admin\b/).empty?
  }
  meet {
    '/etc/sudoers'.p.append("%admin  ALL=(ALL) ALL\n")
  }
end

dep 'admin group' do
  met? { '/etc/group'.p.grep(/^admin\:/) }
  meet { sudo 'groupadd admin' }
end

dep 'tmp cleaning grace period', :for => :ubuntu do
  met? {
    "/etc/default/rcS".p.grep(/^[^#]*TMPTIME=0/).nil?
  }
  meet {
    shell("sed -i'' -e 's/^TMPTIME=0$/TMPTIME=30/' '/etc/default/rcS'")
  }
end
