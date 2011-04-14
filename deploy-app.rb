# coding: utf-8

dep 'app deployed' do
  requires 'db backup exists', '☕ & db'
end

dep '☕ & db', :template => 'benhoskings:task' do
  run { bundle_rake 'barista:brew db:migrate db:autoupgrade data:migrate tc:data:production' }
end

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
  meet { shell "pg_dump tc_production > '#{sqldump}' && gzip -9 '#{sqldump}'" }
  after { shell %Q{ls -t -1 #{backup_prefix} | tail -n+6 | while read f; do rm "#{backup_prefix}/$f"; done} }
end
