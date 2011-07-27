dep 'throttling' do
  requires [
    'nginx-badbots.conf',
    'nginx-noscript.conf',
    'nginx-catchall.conf'
  ]
end

dep 'nginx-badbots.conf' do
  requires 'local fail2ban config'
  met? {
    Babushka::Renderable.new("/etc/fail2ban/filter.d/#{name}").from?(
      dependency.load_path.parent / "throttling/#{name}"
    )
  }
  meet {
    render_erb "throttling/#{name}", to: "/etc/fail2ban/filter.d/#{name}"
  }
end

dep 'nginx-noscript.conf' do
  requires 'local fail2ban config'
  met? {
    Babushka::Renderable.new("/etc/fail2ban/filter.d/#{name}").from?(
      dependency.load_path.parent / "throttling/#{name}"
    )
  }
  meet {
    render_erb "throttling/#{name}", to: "/etc/fail2ban/filter.d/#{name}"
  }
end

dep 'nginx-catchall.conf' do
  requires 'local fail2ban config'
  met? {
    Babushka::Renderable.new("/etc/fail2ban/filter.d/#{name}").from?(
      dependency.load_path.parent / "throttling/#{name}"
    )
  }
  meet {
    render_erb "throttling/#{name}", to: "/etc/fail2ban/filter.d/#{name}"
  }
end

dep 'local fail2ban config' do
  requires 'fail2ban.managed'
  met? {
    Babushka::Renderable.new("/etc/fail2ban/jail.local").from?(
      dependency.load_path.parent / "throttling/jail.local"
    )
  }
  meet {
    render_erb "throttling/jail.local", to: "/etc/fail2ban/jail.local"
  }
end

dep 'fail2ban.managed' do
  provides %w[fail2ban-client fail2ban-server fail2ban-regex]
end
