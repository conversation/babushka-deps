dep 'chat' do
  requires 'chat.supervisor'
end

dep 'chat.supervisor' do
  requires 'chat app'
  command "node chat_server.js"
  user "chat.theconversation.edu.au"
  directory "/srv/http/#{user}/current"
  met? {
    (shell("curl -I localhost:9000") || '').val_for('Server')['node']
  }
end

dep 'chat app' do
  requires [
    'chat app symlinked in',
    'socket.io.npm'
  ]
end

dep 'chat app symlinked in' do
  def path
    'public/javascripts/chat_server.js'
  end
  set :rails_root, "/srv/http/theconversation.edu.au/current"
  setup {
    (var(:rails_root)/path).exists?.tap {|result|
      log_error "#{var(:rails_root)/path} doesn't exist - it will be rendered by barista on deploy." unless result
    }
  }
  met? { "~/current/chat_server.js".p.exists? }
  before { "~/current".p.mkdir }
  meet { shell "ln -sf #{var(:rails_root)}/#{path} ~/current" }
end

dep 'socket.io.npm' do
  installs 'socket.io 0.6.15'
  provides []
end
