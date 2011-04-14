dep 'db backup exists' do
  @backup_time = Time.now

  def backup_prefix
    "~/sqldumps".p
  end

  def refspec
    shell "git rev-parse --short HEAD"
  end

  def sqldump
    backup_prefix / "tc_production-#{refspec}-#{@backup_time.strftime("%Y-%m-%d-%H:%M:%S")}.psql"
  end

  def backup_path
    "#{sqldump}.gz".p
  end

  met? { backup_path.exists? }
  before { backup_prefix.mkdir }
  meet { log_shell "Dumping the production db", "pg_dump tc_development > '#{sqldump}' && gzip -9 '#{sqldump}'" }
  after { log_shell "Removing old backups", %Q{ls -t -1 #{backup_prefix} | tail -n+6 | while read f; do rm "#{backup_prefix}/$f"; done} }
end
