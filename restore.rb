dep "pg recovered", :data_dir, :backup_host, :backup_name do
  requires "pg recovery started".with(data_dir, backup_host, backup_name)
  met? do
    loop do
      log "The data dir measures #{shell("du -s -m '#{data_dir}'").scan(/^\d+/).first}MB."
      sleep 2
    end until (data_dir / "recovery.done").file?
  end
end

dep "pg recovery started", :data_dir, :backup_host, :backup_name do
  # requires 'pg backup in place'.with(data_dir, backup_host, backup_name)
  met? do
    (data_dir / "postmaster.pid").exists?
  end
  meet do
    shell("pg_ctl start -D /usr/local/var/postgres -l /usr/local/var/postgres/server.log")
  end
end

dep "pg backup in place", :data_dir, :backup_host, :backup_name, template: "task" do
  requires "pg shut down".with(data_dir)
  def src
    "postgres@#{backup_host}:~/backups/#{backup_name}/"
  end

  def dest
    "#{data_dir.to_s.chomp('/')}/"
  end
  run do
    log_block "rsyncing the #{backup_name} backup from #{backup_host} to #{data_dir}" do
      shell "rsync -taP --delete --exclude=postmaster.{opts,pid} '#{src}' '#{dest}'", progress: /to-check=\d+\/\d+/
    end
  end
end

dep "pg shut down", :data_dir do
  met? do
    !(data_dir / "postmaster.pid").exists?
  end
  meet do
    shell "pg_ctl stop --pgdata '#{data_dir}'"
  end
end
