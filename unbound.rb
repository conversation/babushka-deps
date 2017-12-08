dep "unbound" do
  requires "unbound configured"
  requires "unbound.bin"
end

dep "unbound configured" do
  def renderable_conf
    "unbound/unbound.conf.erb"
  end

  def system_conf
    "/etc/unbound/unbound.conf"
  end

  def system_conf_dir
    "/etc/unbound"
  end

  def renderable_default
    "unbound/default"
  end

  def system_default
    "/etc/default/unbound"
  end

  met? do
    Babushka::Renderable.new(system_conf).from?(dependency.load_path.parent / renderable_conf) &&
     Babushka::Renderable.new(system_default).from?(dependency.load_path.parent / renderable_default)
  end
  meet do
    shell "mkdir -p #{system_conf_dir}"
    render_erb renderable_conf, to: system_conf, sudo: true
    render_erb renderable_default, to: system_default, sudo: true
  end
end
