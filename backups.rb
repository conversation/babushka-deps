dep 'db backup exists' do
  @backup_time = Time.now

  def backup_prefix; "~/sqldumps".p end
  def refspec; shell "git rev-parse --short HEAD" end
  def sqldump; backup_prefix / "tc_production-#{refspec}-#{@backup_time.strftime("%Y-%m-%d-%H:%M:%S")}.psql" end
  def backup_path; "#{sqldump}.gz".p end

  met? { backup_path.exists? }
  before { backup_prefix.mkdir }
  meet { log_shell "Dumping the production db", "pg_dump tc_production > '#{sqldump}' && gzip -9 '#{sqldump}'" }
  after { log_shell "Removing old backups", %Q{ls -t -1 #{backup_prefix} | tail -n+6 | while read f; do rm "#{backup_prefix}/$f"; done} }
end

dep 'offsite backup.cloudfiles' do
  def backup_path
    # TODO: make this better
    Dep('db backup exists', from: dependency.dep_source).context.backup_path
  end

  def md5 backup_path
    cmd = which('md5') ? 'md5 -q' : 'md5sum'
    shell("#{cmd} '#{backup_path}'").split(/\s/, 2).first
  end

  requires 'db backup exists'

  met? {
    upload_info = get_upload_info
    log "Rackspace returned HTTP #{upload_info.code}.", as: (:ok if upload_info.is_a?(Net::HTTPSuccess))

    if upload_info.is_a?(Net::HTTPSuccess)
      local_hash = md5(backup_path)
      remote_hash = upload_info.header.to_hash['etag'].first
      if local_hash != remote_hash
        unmet "Checksum mismatch: local was #{local_hash} but rackspace reported #{remote_hash}."
      else
        met "Rackspace says the file is intact."
      end
    end
  }
  meet {
    do_cloud_upload
  }
end
