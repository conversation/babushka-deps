dep 'db restored', :env, :app_user, :db_name, :app_root, :backup_path do

  requires 'benhoskings:existing postgres db'.with(app_user, db_name)
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
