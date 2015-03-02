dep 'unbound' do
  requires 'unbound configured'
end

dep 'unbound configured' do
  requires 'unbound.bin'

  def renderable_conf
    "unbound/unbound.conf.erb"
  end

  def system_conf
    "/etc/unbound/unbound.conf"
  end

  met? {
    Babushka::Renderable.new(system_conf).from?(dependency.load_path.parent / renderable_conf)
  }
  meet {
    render_erb renderable_conf, :to => system_conf, :sudo => true
  }
end
