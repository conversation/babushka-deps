dep 'sharejs', :username, :env, :db_name do
  requires [
    'sharejs.supervisor'.with(username, env, db_name)
  ]
end


dep 'sharejs.supervisor', :username, :env, :db_name do
  requires 'sharejs app'.with(username, db_name)

  username.default!(shell('whoami'))
  db_name.default!("tc_#{env}")

  command "coffee app.coffee"
  environment %Q{NODE_ENV="#{env}"}
  user username
  directory "/srv/http/#{user}/current"

  met? {
    ((shell("curl -I localhost:9000") || '').val_for('X-Refspec') || '').length > 0
  }
end

dep 'sharejs app', :username, :db_name do
  requires [
    'sharejs db permissions'.with(username, db_name),
    'npm packages installed',
  ]
end

dep 'npm packages installed', :template => "benhoskings:task" do
  # No apparent equivalent for bundle check command
  run { shell %Q{npm install}, :cd => "~/current" }
end

dep 'sharejs db permissions', :username, :db_name do
  requires 'schema access'.with(username, db_name, "sharejs", "sharejs.article_draft_snapshots")
end

dep 'schema access', :username, :db_name, :schema_name, :check_table_name do
  requires 'benhoskings:postgres access'.with(username)
  met? { shell? "psql #{db_name} -c 'SELECT * FROM #{check_table_name} LIMIT 1'" }
  meet { sudo %Q{psql #{db_name} -c 'GRANT ALL PRIVILEGES ON SCHEMA #{schema_name} TO "#{username}"'}, :as => 'postgres' }
end
