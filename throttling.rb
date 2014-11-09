dep 'throttling', :env do
  requires 'local fail2ban config'.with(env)
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
