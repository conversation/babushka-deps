# coding: utf-8

dep 'app deployed' do
  requires '☕ & db', 'db backup exists'
end

dep '☕ & db', :template => 'benhoskings:task' do
  run { bundle_rake 'barista:brew db:migrate db:autoupgrade data:migrate tc:data:production' }
end

dep 'db backup exists' do
  @backup_time = Time.now

  def backup_prefix
    "~/sqldumps".p
  end

  def backup_file
    backup_prefix / "#{@backup_time.strftime("%Y-%m-%d %H:%M:%S")}.psql"
  end
  
  met? { backup_file.exists? }
  before { backup_prefix.mkdir }
  meet { shell "pg_dump tc_production > '#{backup_file}'" }
  after { shell %Q{ls -t -1 #{backup_prefix} | tail -n+6 | while read f; do rm "$f"; done} }
end
