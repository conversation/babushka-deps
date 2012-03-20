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
  restart 'always'

  start_delay 10

  met? {
    ((shell("curl -I localhost:9000") || '').val_for('X-Refspec') || '').length > 0
  }
end

dep 'sharejs app', :username, :tc_username, :db_name do
  tc_username.default!('theconversation.edu.au')
  requires [
    'schema ownership'.with(username, db_name, "sharejs"),
    'sharejs tables exist'.with(username, db_name),
    'read-only schema access'.with(tc_username, username, db_name, 'sharejs', 'sharejs.article_draft_snapshots'),
    'read-only db access'.with(db_name, 'sharejs', tc_username, 'sharejs.article_draft_snapshots'),
    'npm packages installed',
  ]
end

dep 'sharejs tables exist', :username, :db_name do
  requires 'table exists'.with(username, db_name, 'sharejs.article_draft_operations', <<-SQL)
    doc text NOT NULL,
    v int4 NOT NULL,
    op text NOT NULL,
    meta text NOT NULL,
    CONSTRAINT operations_pkey PRIMARY KEY (doc, v)
  SQL

  requires 'table exists'.with(username, db_name, 'sharejs.article_draft_snapshots', <<-SQL)
    doc text NOT NULL,
    v int4 NOT NULL,
    type text NOT NULL,
    snapshot text NOT NULL,
    meta text NOT NULL,
    created_at timestamp(6) NOT NULL,
    CONSTRAINT snapshots_pkey PRIMARY KEY (doc, v)
  SQL
end

dep 'npm packages installed', :template => "benhoskings:task" do
  # No apparent equivalent for bundle check command
  run { shell %Q{npm install}, :cd => "~/current" }
end
