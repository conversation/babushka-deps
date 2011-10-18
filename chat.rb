dep 'chat', :username do
  requires 'chat.supervisor'.with(username: username)
end

dep 'chat.supervisor', :username, :db_name, :tc_path do
  requires 'chat app'.with(username, db_name, tc_path)

  db_name.default!('tc_production')
  tc_path.default!('/srv/http/theconversation.edu.au/current')

  command "node chat_server.js"
  environment %Q{NODE_PATH="/usr/local/lib/node_modules"}, %Q{CHAT_DB="#{db_name}"}
  user "chat.theconversation.edu.au"
  directory "/srv/http/#{user}/current"

  met? {
    ((shell("curl -I localhost:9000") || '').val_for('Server') || '')['node.js']
  }
end

dep 'chat app', :username, :db_name, :tc_path do
  requires [
    'chat db permissions'.with(username, db_name),
    'chat app symlinked in'.with(tc_path),
    'socket.io.npm',
    'pg.npm'
  ]
end

dep 'chat db permissions', :username, :db_name do
  requires 'messages access'.with(username, db_name)
  requires 'messages_id_seq access'.with(username, db_name)
end

dep 'messages access', :username, :db_name do
  requires 'benhoskings:postgres access'.with(username)
  met? { shell "psql #{db_name} -c 'SELECT id FROM messages LIMIT 1'" }
  meet { sudo %Q{psql #{db_name} -c 'GRANT SELECT,INSERT ON messages TO "#{username}"'}, as: 'postgres' }
end

dep 'messages_id_seq access', :username, :db_name do
  requires 'benhoskings:postgres access'.with(username)
  met? { shell "psql #{db_name} -c 'SELECT sequence_name FROM messages_id_seq LIMIT 1'" }
  meet { sudo %Q{psql #{db_name} -c 'GRANT SELECT,UPDATE ON messages_id_seq TO "#{username}"'}, as: 'postgres' }
end

dep 'chat app symlinked in', :tc_path do
  def path
    'public/javascripts/chat_server.js'
  end

  setup {
    (tc_path/path).exists?.tap {|result|
      log_error "#{tc_path/path} doesn't exist - it will be rendered by barista on deploy." unless result
    }
  }
  met? { "~/current/chat_server.js".p.exists? }
  before { "~/current".p.mkdir }
  meet { shell "ln -sf #{tc_path}/#{path} ~/current" }
end

dep 'socket.io.npm' do
  installs 'socket.io 0.6.15'
end

dep 'pg.npm' do
  installs 'pg 0.5.5'
end
