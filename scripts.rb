dep "script installed", :script_name do
  def up_to_date?(source, dest)
    Babushka::Renderable.new(dest).from?(source) && Babushka::Renderable.new(dest).clean?
  end

  def source_script
    dependency.load_path.parent / "scripts" / script_name
  end

  def dest_path
    "/usr/local/bin/#{script_name}"
  end

  met? do
    up_to_date?(source_script, dest_path) && File.stat(dest_path).executable?
  end
  meet do
    render_erb(source_script, to: dest_path, sudo: true)
    log_shell "Making #{dest_path} executable", "chmod +x #{dest_path}", sudo: true
  end
end
