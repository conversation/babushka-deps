
dep 'sharejs.upstart', :username, :tc_username, :env, :db_name do
  requires 'sharejs setup'.with(username, tc_username, db_name)

  username.default!(shell('whoami'))
  db_name.default!("tc_#{env}")

  command "coffee app.coffee"
  environment %Q{NODE_ENV=#{env.to_s.inspect}}
  setuid username
  chdir "/srv/http/#{username}/current"
  respawn 'yes'

  met? {
    (shell("curl -I localhost:9000", &:stdout).val_for('X-Refspec') || '')[/\w{7,}/]
  }
end

dep 'sharejs setup', :username, :tc_username, :db_name do
  tc_username.default!('theconversation.com')
  requires [
    'schema ownership'.with(username, db_name, "sharejs"),
    'schema loaded'.with(:username => username, :root => root, :db_name => db_name),
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
