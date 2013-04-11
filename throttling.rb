dep 'throttling' do
  requires [
    'fail2ban filter'.with('nginx-badbots'),
    'fail2ban filter'.with('nginx-noscript'),
    'fail2ban filter'.with('nginx-catchall'),
    'fail2ban filter'.with('user-signup'),
  ]
end

dep 'fail2ban filter', :filter_name do
  def filter_file
    "#{filter_name}.conf"
  end
  requires 'local fail2ban config'
  met? {
    Babushka::Renderable.new("/etc/fail2ban/filter.d/#{filter_file}").from?(
      dependency.load_path.parent / "throttling/#{filter_file}"
    )
  }
  meet {
    render_erb "throttling/#{filter_file}", :to => "/etc/fail2ban/filter.d/#{filter_file}"
  }
end

dep 'local fail2ban config' do
  requires 'fail2ban.bin'
  met? {
    Babushka::Renderable.new("/etc/fail2ban/jail.local").from?(
      dependency.load_path.parent / "throttling/jail.local"
    )
  }
  meet {
    render_erb "throttling/jail.local", :to => "/etc/fail2ban/jail.local"
  }
end

dep 'fail2ban.bin' do
  provides %w[fail2ban-client fail2ban-server fail2ban-regex]
end
