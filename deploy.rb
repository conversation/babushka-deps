dep 'db backed up', :env do
  env.default!(ENV['RAILS_ENV'] || 'production')
  setup {
    if env != 'production'
      log "Skipping DB backup on #{env}."
    else
      requires 'offsite backup.cloudfiles'.with(:db_name => 'tc_production')
    end
  }
end

dep 'migrate db', :env, :template => 'benhoskings:task' do
  # requires 'benhoskings:maintenance page up'
  run {
    shell! "bundle exec rake db:migrate db:autoupgrade tc:data:#{env} --trace RAILS_ENV=#{env}", :log => true
  }
end

dep 'cache cleared' do
  met? {
    shell("git clean -ndx public/*.html public/pages/*.html").empty?
  }
  meet {
    shell "git clean -fdx public/*.html public/pages/*.html", log: true
  }
end
