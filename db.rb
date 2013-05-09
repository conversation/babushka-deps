dep 'db', :username, :root, :env, :data_required, :require_db_deps do
  def db_config
    (root / 'config/database.yml').yaml[env.to_s].tap {|config|
      unmeetable! "There's no database.yml entry for the #{env} environment." if config.nil?
    }
  end

  def db_type
    # Use 'postgres' when rails says 'postgresql' or similar.
    db_config['adapter'].sub('postgresql', 'postgres')
  end

  require_db_deps.default!('yes')

  requires 'app bundled'.with(root, env)

  if require_db_deps[/^y/]
    requires 'db gem'.with(db_type)
    if data_required[/^y/]
      requires "existing data".with(username, db_config['database'])
      requires "migrated db".with(username, root, env, db_config['database'], db_type, 'no')
    else
      requires "seeded db".with(username, root, env, db_config['database'], db_type)
    end
  end
end

dep 'seeded db', :username, :root, :env, :db_name, :db_type, :template => 'task' do
  requires "migrated db".with(username, root, env, db_name, db_type, 'no')
  root.default!('.')
  run {
    shell "bundle exec rake db:seed --trace RAILS_ENV=#{env} RACK_ENV=#{env}", :cd => root, :log => true
  }
end

dep 'migrated db', :username, :root, :env, :db_name, :db_type, :deploying, :template => 'task' do
  root.default!('.')
  deploying.default!('no')
  requires 'schema loaded'.with(:username => username, :root => root, :db_name => db_name, :db_type => db_type) unless deploying[/^y/]
  run {
    shell! "bundle exec rake db:migrate --trace RAILS_ENV=#{env} RACK_ENV=#{env}", :cd => root, :log => true
  }
end

dep 'schema loaded', :username, :root, :schema_path, :db_name, :db_type do
  root.default!('.')
  schema_path.default!('db/schema.sql')
  requires 'existing db'.with(username, db_name, db_type)
  met? {
    shell(
      %Q{psql #{db_name} -t -c "SELECT count(*) FROM pg_tables WHERE schemaname = 'public'"}
    ).to_i.tap {|tables|
      log "There are #{tables} tables in #{db_name}."
    } > 0
  }
  meet {
    log_shell "Applying #{schema_path} to #{db_name}", "psql #{db_name} -f -", :input => (root / schema_path).p.read!
  }
end

dep 'existing db', :username, :db_name, :db_type do
  requires "existing #{db_type} db".with(username, db_name)
end

dep 'db gem', :db do
  db.choose(%w[postgres mysql])
  requires db == 'postgres' ? 'pg.gem' : "#{db}.gem"
end

dep 'db restored', :env, :app_user, :db_name, :app_root, :backup_path do

  requires 'existing postgres db'.with(app_user, db_name)
  requires_when_unmet 'db backup from cloudfiles'.with(app_root, backup_path)

  met? {
    table_count = shell("psql #{db_name} -c '\\d'").scan(/\((\d+) rows?\)/).flatten.first

    table_count && table_count.to_i > 0
  }

  meet {
    log_shell(
      "Loading the database backup into #{db_name}",
      "gzip -dc #{backup_path} | sudo -u postgres psql #{db_name}",
      :spinner => true
    )
  }
end

dep 'db backup from cloudfiles', :app_root, :backup_path do
  require app_root.p.join('lib/tc/cloud_info')
  require app_root.p.join('lib/tc/cloud_bucket')

  def bucket
    @bucket ||= TC::CloudBucket.new('tc_db_backups')
  end

  backup_path.default!(app_root.p / 'tmp/tc_production.psql.gz')

  met? {
    if !backup_path.p.exists?
      log "The backup hasn't been downloaded yet."
    elsif backup_path.p.mtime < (Time.now - (5 * 3600))
      log "The downloaded backup is stale (#{(Time.now - backup_path.p.mtime).round.xsecs} old)."
    elsif !log_block("Verifying the backup") { shell?("gzip -t #{backup_path}") }
      log "The downloaded backup isn't a valid gzip (the download was probably cancelled)."
    else
      log_ok "The downloaded backup is a valid gzip downloaded #{(Time.now - backup_path.p.mtime).round.xsecs} ago."
    end
  }
  meet {
    latest_backup = bucket.search("tc_production").sort.last
    bucket.download(latest_backup, backup_path.to_s)
  }
end
