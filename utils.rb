dep 'cron jobs' do
  def job_path job_name
    "/etc/cron.#{job_name}/tc_#{job_name}".p
  end
  def missing_jobs
    %w[daily weekly].reject {|job|
      job_path(job).exists?
    }
  end
  met? { missing_jobs.empty? }
  meet {
    missing_jobs.each {|job|
      sudo "ln -sf '#{var(:rails_root)/'script/tasks'/job}' '#{job_path(job)}'"
    }
  }
end

dep 'ssl cert in place', :template => 'benhoskings:nginx' do
  def names
    %w[key crt].map {|ext| "#{var(:domain)}.#{ext}" }
  end
  met? {
    names.all? {|name| (nginx_cert_path / name).exists? }
  }
  before {
    sudo "mkdir -p #{nginx_cert_path}"
  }
  meet {
    names.each {|name| sudo "cp '#{var(:cert_path) / name}' #{nginx_cert_path.to_s.end_with('/')}" }
  }
end

dep 'asset backups' do
  requires 'rsync.managed'
  met? { "/etc/cron.hourly/tc_asset_backups".p.readlink == "~#{var(:username)}/current/script/asset_backups.sh".p }
  meet { sudo "ln -s ~#{var(:username)}/current/script/asset_backups.sh /etc/cron.hourly/tc_asset_backups" }
end
