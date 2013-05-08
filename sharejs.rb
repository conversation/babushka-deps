
dep 'sharejs.upstart', :username, :tc_username, :env, :db_name do
  requires 'sharejs setup'.with(username, tc_username, db_name)

  username.default!(shell('whoami'))
  db_name.default!("tc_#{env}")

  command "coffee app.coffee"
  environment %Q{NODE_ENV=#{env.to_s.inspect}}
  setuid username
  chdir "/srv/http/#{username}/current"
  respawn 'true'

  met? {
    (shell("curl -I localhost:9000", &:stdout).val_for('X-Refspec') || '')[/\w{7,}/]
  }
end

dep 'sharejs setup', :username, :tc_username, :db_name do
  tc_username.default!('theconversation.edu.au')
  requires [
    'schema ownership'.with(username, db_name, "sharejs"),
    'sharejs tables exist'.with(username, db_name),
    'schema access'.with(tc_username, username, db_name, 'sharejs', 'sharejs.article_draft_snapshots'),
    'db access'.with(
      :db_name => db_name,
      :schema => 'sharejs',
      :username => tc_username,
      :check_table => 'sharejs.article_draft_snapshots'
    ),
    'npm packages installed'.with('~/current'),
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

dep 'npm packages installed', :path do
  met? {
    output = raw_shell('npm ls', :cd => path)
    # Older `npm` versions exit 0 on failure.
    output.ok? && output.stdout['UNMET DEPENDENCY'].nil?
  }
  meet {
    shell('npm install', :cd => path)
  }
end
