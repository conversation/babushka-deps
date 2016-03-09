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
    'pv.bin',
    'ntpd.bin',
    's3cmd',
    'trickle.bin'
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

dep 'local caching dns server' do
  requires "unbound"

  def up_to_date?(source_name, dest)
    source = dependency.load_path.parent / source_name
    Babushka::Renderable.new(dest).from?(source) && Babushka::Renderable.new(dest).clean?
  end

  met? {
    up_to_date?("system/resolv.conf.erb", "/etc/resolv.conf")
  }
  meet {
    render_erb "system/resolv.conf.erb", :to => "/etc/resolv.conf", :sudo => true
  }
end

dep 'monitored with collectd' do
  requires 'collectd.bin'

  def conf_files
    {
      "collectd/collectd.conf.erb" => "/etc/collectd/collectd.conf",
      "collectd/10_write_http.conf.erb" => "/etc/collectd/collectd.conf.d/10_write_http.conf",
      "collectd/20_aggregation.conf.erb" => "/etc/collectd/collectd.conf.d/20_aggregation.conf",
      "collectd/30_df.conf.erb" => "/etc/collectd/collectd.conf.d/30_df.conf",
      "collectd/30_disk.conf.erb" => "/etc/collectd/collectd.conf.d/30_disk.conf",
      "collectd/30_interface.conf.erb" => "/etc/collectd/collectd.conf.d/30_interface.conf",
      "collectd/30_load.conf.erb" => "/etc/collectd/collectd.conf.d/30_load.conf",
      "collectd/30_memcached.conf.erb" => "/etc/collectd/collectd.conf.d/30_memcached.conf",
      "collectd/30_ntpd.conf.erb" => "/etc/collectd/collectd.conf.d/30_ntpd.conf",
      "collectd/30_processes.conf.erb" => "/etc/collectd/collectd.conf.d/30_processes.conf",
      "collectd/30_statsd.conf.erb" => "/etc/collectd/collectd.conf.d/30_statsd.conf",
      "collectd/30_swap.conf.erb" => "/etc/collectd/collectd.conf.d/30_swap.conf",
      "collectd/30_uptime.conf.erb" => "/etc/collectd/collectd.conf.d/30_uptime.conf",
      "collectd/30_users.conf.erb" => "/etc/collectd/collectd.conf.d/30_users.conf"
    }
  end

  def up_to_date?(source_name, dest)
    source = dependency.load_path.parent / source_name
    Babushka::Renderable.new(dest).from?(source) && Babushka::Renderable.new(dest).clean?
  end

  def monitored_network_interface
    shell("ifconfig -s", :sudo => true).split("\n").map { |line|
      line[/^([a-z]+\d)\s+/,1]
    }.compact.first || "eth0"
  end

  def root_partition_name
    shell("df").split("\n").select { |line|
      line[/\/\Z/]
    }.map { |line|
      line[/\A([^\s]+)/,1]
    }.map { |line|
      line.gsub("/dev/","")
    }.first
  end

  met? {
    conf_files.all? { |source, dest| up_to_date?(source, dest) }
  }
  meet {
    conf_files.each { |source, dest|
      render_erb(source, :to => dest, :sudo => true)
    }
    log_shell "Restarting collectd", "/etc/init.d/collectd restart", :sudo => true
  }
end

dep 'lax host key checking' do
  def ssh_conf_path file
    "/etc#{'/ssh' if Babushka.host.linux?}/#{file}_config"
  end
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
