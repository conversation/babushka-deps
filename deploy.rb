# coding: utf-8

dep 'deployed' do
  requires '☕ & db', 'db backup exists'
end

dep '☕ & db', :template => 'benhoskings:task' do
  run { bundle_rake 'barista:brew db:migrate db:autoupgrade data:migrate' }
end

dep 'db backup exists' do
  @backup_time = Time.now

  def backup_file
    "~/sqldumps/#{@backup_time.strftime("%Y-%m-%d %H:%M:%S")}.psql".p
  end
  
  met? { backup_file.exists? }
  before { '~/sqldumps'.p.mkdir }
  meet { shell "pg_dump tc_production > '#{backup_file}'" }
end
