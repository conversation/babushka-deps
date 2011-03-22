dep 'chat' do
  requires 'chat.supervisor'
end

dep 'chat.supervisor' do
  requires 'chat app'

  set :chat_db, 'tc_production'

  command "node chat_server.js"
  environment "CHAT_DB=#{var(:chat_db)}"
  user "chat.theconversation.edu.au"
  directory "/srv/http/#{user}/current"

  met? {
    (shell("curl -I localhost:9000") || '').val_for('Server')['node.js']
  }
end

dep 'chat app' do
  requires [
    'database permissions',
    'chat app symlinked in',
    'socket.io.npm',
    'pg.npm'
  ]
end

dep 'database permissions' do
  requires 'messages access', 'messages_id_seq access'
end

dep 'messages access' do
  requires 'benhoskings:postgres access'
  met? { shell "psql #{var(:chat_db)} -c 'SELECT id FROM messages LIMIT 1'" }
  meet { sudo %Q{psql #{var(:chat_db)} -c 'GRANT SELECT,INSERT ON messages TO "#{var(:username)}"'}, as: 'postgres' }
end

dep 'messages_id_seq access' do
  requires 'benhoskings:postgres access'
  met? { shell "psql #{var(:chat_db)} -c 'SELECT sequence_name FROM messages_id_seq LIMIT 1'" }
  meet { sudo %Q{psql #{var(:chat_db)} -c 'GRANT SELECT,UPDATE ON messages_id_seq TO "#{var(:username)}"'}, as: 'postgres' }
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
end

dep 'pg.npm' do
  installs 'pg 0.3.2'
end