dep 'db recovered', :data_dir, :backup_host, :backup_name do

  requires 'db recovery started'.with(data_dir, backup_host, backup_name)
  met? {
    loop {
      log "The data dir measures #{shell("du -s -m '#{data_dir}'").scan(/^\d+/).first}MB."
      sleep 2
    } until (data_dir / 'recovery.done').file?
  }
end

dep 'db recovery started', :data_dir, :backup_host, :backup_name do
  requires 'backup data in place'.with(data_dir, backup_host, backup_name)
  meet {
    render_erb 'postgres/recovery.conf.erb', :to => (data_dir / 'recovery.conf')
    shell("pg_ctl restart -D #{data_dir}")
  }
end

dep 'backup data in place', :data_dir, :backup_host, :backup_name do
  requires_when_unmet 'empty local cluster'.with(data_dir)
  met? {
    
  }
  meet {
    log_block "rsyncing the #{backup_name} backup from #{backup_host} to #{data_dir}" do
      shell "rsync -taP --delete 'postgres@#{backup_host}:~/backups/#{backup_name}/' #{data_dir.to_s.chomp('/')}/", :progress => /to-check=\d+\/\d+/
    end
  }
end

dep 'empty local cluster', :data_dir do
  met? {
    data_dir.p.empty?
  }
  meet {
    local_dbs = shell("psql -l -t | sed -e 's/|.*$//'").split(/\n+/) - %w[postgres template0 template1]
    confirm "The #{data_dir} cluster contains #{local_dbs.empty? ? 'no DBs' : local_dbs.to_list}. OK to delete?" do
      data_dir.p.rm.mkdir
    end
  }
end
