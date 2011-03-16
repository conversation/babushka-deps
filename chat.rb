dep 'chat' do
  requires 'chat.supervisor'
end

dep 'chat.supervisor' do
  requires 'nodejs.src', 'chat code symlinked in'
  command "node chat_server.js"
  user "chat.theconversation.edu.au"
  directory "/srv/http/#{user}/current"
  met? {
    (shell("curl -I localhost:9000") || '').val_for('Server')['node']
  }
end

dep 'chat code symlinked in' do
  def path
    'public/javascripts/chat_server.js'
  end
  requires 'app in place'
  set :rails_root, "/srv/http/theconversation.edu.au/current"
  met? { ("~/current"/path).exists? }
  before { "~/current".p.mkdir }
  meet { shell "ln -sf #{var(:rails_root)}/#{path} ~/current" }
end
