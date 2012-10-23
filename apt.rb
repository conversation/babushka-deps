dep 'our apt source' do
  requires 'apt source'.with(:uri => 'http://apt.tc-dev.net/', :repo => 'main')
  requires 'gpg key'.with('B6D8A3F9')
end

dep 'apt sources' do
  met? {
    Babushka::Renderable.new("/etc/apt/sources.list").from?(dependency.load_path.parent / "apt/sources.list.erb")
  }
  meet {
    render_erb "apt/sources.list.erb", :to => "/etc/apt/sources.list"
    shell "rm -f /etc/apt/sources.list.d/babushka.list"
    shell "apt-get update"
  }
end
