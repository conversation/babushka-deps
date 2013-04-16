dep 'throttling', :env do
  requires [
    'fail2ban filter'.with('nginx-badbots', env),
    'fail2ban filter'.with('nginx-noscript', env),
    'fail2ban filter'.with('user-signup', env),
  ]
end

dep 'fail2ban filter', :filter_name, :env do
  def filter_file
    "#{filter_name}.conf"
  end
  requires 'local fail2ban config'.with(env)
  met? {
    Babushka::Renderable.new("/etc/fail2ban/filter.d/#{filter_file}").from?(
      dependency.load_path.parent / "throttling/#{filter_file}"
    )
  }
  meet {
    render_erb "throttling/#{filter_file}", :to => "/etc/fail2ban/filter.d/#{filter_file}"
    shell "/etc/init.d/fail2ban restart"
  }
end

dep 'local fail2ban config', :env do
  requires 'fail2ban.bin'
  met? {
    Babushka::Renderable.new("/etc/fail2ban/jail.local").from?(
      dependency.load_path.parent / "throttling/jail.local.erb"
    )
  }
  meet {
    render_erb "throttling/jail.local.erb", :to => "/etc/fail2ban/jail.local"
    shell "/etc/init.d/fail2ban restart"
  }
end

dep 'fail2ban.bin' do
  provides %w[fail2ban-client fail2ban-server fail2ban-regex]
end
