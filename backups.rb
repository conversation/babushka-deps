dep 'db backup exists', :backup_path do
  @backup_time = Time.now

  def backup_prefix; "~/sqldumps".p end
  def refspec; shell "git rev-parse --short HEAD" end
  def sqldump; backup_prefix / "tc_production-#{@backup_time.strftime("%Y-%m-%d-%H:%M:%S")}-#{refspec}.psql" end

  backup_path.default!("#{sqldump}.gz")

  met? { backup_path.p.exists? }
  before { backup_prefix.mkdir }
  meet { log_shell "Creating #{sqldump} from tc_production", "pg_dump tc_production > '#{sqldump}' && gzip -9 '#{sqldump}'" }
  after { log_shell "Removing old sqldumps", %Q{ls -t -1 #{backup_prefix} | tail -n+6 | while read f; do rm "#{backup_prefix}/$f"; done} }
end

dep 'offsite backup.cloudfiles', :backup_path do
  def md5
    cmd = which('md5') ? 'md5 -q' : 'md5sum'
    shell("#{cmd} '#{backup_path}'").split(/\s/, 2).first
  end

  requires 'db backup exists'.with(backup_path)

  met? {
    upload_info = get_upload_info
    log "Rackspace returned HTTP #{upload_info.code}.", as: (:ok if upload_info.is_a?(Net::HTTPSuccess))

    if upload_info.is_a?(Net::HTTPSuccess)
      local_hash = md5
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
