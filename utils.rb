dep 'crontab' do
  setup {
    @hour = 11 # 1am in GMT+10
    @min = rand(60)
  }
  met? {
    babushka_config? "/etc/crontab"
  }
  meet {
    render_erb "utils/crontab.erb", :to => "/etc/crontab", :sudo => true
  }
end

dep 'cron jobs' do
  def job_path job_name
    "/etc/cron.#{job_name}/tc_#{job_name}".p
  end
  def missing_jobs
    %w[hourly daily weekly].reject {|job|
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
