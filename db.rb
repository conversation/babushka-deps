dep "db", :username, :root, :env, :data_required, :require_db_deps do
  require_db_deps.default!("yes")

  requires "app bundled".with(root, env)

  if require_db_deps[/^y/]
    if data_required[/^y/]
      requires "existing data".with(username, Util.database_name(root, env))
      requires "migrated db".with(username, root, env, Util.database_name(root, env), "no")
    else
      requires "seeded db".with(username, root, env, Util.database_name(root, env))
    end
  end
end

dep "seeded db", :username, :root, :env, :db_name, template: "task" do
  requires "migrated db".with(username, root, env, db_name, "no")
  root.default!(".")
  run do
    shell "bundle exec rake db:seed --trace RAILS_ENV=#{env} RACK_ENV=#{env}", cd: root, log: true
  end
end

dep "migrated db", :username, :root, :env, :db_name, :deploying, template: "task" do
  root.default!(".")
  deploying.default!("no")
  requires "schema loaded".with(username: username, root: root, db_name: db_name) unless deploying[/^y/]
  run do
    shell! "bundle exec rake db:migrate --trace RAILS_ENV=#{env} RACK_ENV=#{env}", cd: root, log: true
  end
end

dep "schema loaded", :username, :root, :schema_path, :db_name do
  root.default!(".")
  schema_path.default!(root / "db/schema.sql")
  requires "existing db".with(username, db_name)

  met? do
    shell(
      %Q{psql #{db_name} -t -c "SELECT count(*) FROM pg_tables WHERE schemaname NOT IN ('pg_catalog','information_schema')"}
    ).to_i.tap do |tables|
      log "There are #{tables} tables in #{db_name}."
    end > 0
  end

  meet do
    log_shell "Applying #{schema_path} to #{db_name}", "psql #{db_name} -f -", input: schema_path.p.read!
  end
end

dep "db restored", :env, :app_user, :db_name, :app_root, :backup_path do
  requires "existing db".with(app_user, db_name)
  requires_when_unmet "db backup from cloudfiles".with(app_root, backup_path)

  met? do
    table_count = shell("psql #{db_name} -c '\\d'").scan(/\((\d+) rows?\)/).flatten.first

    table_count && table_count.to_i > 0
  end

  meet do
    log_shell(
      "Loading the database backup into #{db_name}",
      "gzip -dc #{backup_path} | sudo -u postgres psql #{db_name}",
      spinner: true
    )
  end
end

dep "db backup from cloudfiles", :app_root, :backup_path do
  requires "raca.gem"

  def cloudfiles_username
    YAML.load_file(app_root.p.join("config/application.yml"))["cloudfiles"]["username"]
  end

  def cloudfiles_api_key
    YAML.load_file(app_root.p.join("config/application.yml"))["cloudfiles"]["api_key"]
  end

  def bucket
    require "raca"
    @bucket ||= begin
      account = Raca::Account.new(cloudfiles_username, cloudfiles_api_key)
      account.containers(:ord).get("tc_db_backups")
    end
  end

  backup_path.default!(app_root.p / "tmp/tc_production.psql.gz")

  met? do
    if !backup_path.p.exists?
      log "The backup hasn't been downloaded yet."
    elsif backup_path.p.mtime < (Time.now - (5 * 3600))
      log "The downloaded backup is stale (#{(Time.now - backup_path.p.mtime).round.xsecs} old)."
    elsif !log_block("Verifying the backup") { shell?("gzip -t #{backup_path}") }
      log "The downloaded backup isn't a valid gzip (the download was probably cancelled)."
    else
      log_ok "The downloaded backup is a valid gzip downloaded #{(Time.now - backup_path.p.mtime).round.xsecs} ago."
    end
  end

  meet do
    latest_backup = bucket.search("tc_production").sort.last
    bucket.download(latest_backup, backup_path.to_s)
  end
end
