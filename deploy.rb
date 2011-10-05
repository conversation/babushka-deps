dep 'db', :env do
  setup {
    if !shell?('psql -l tc_production')
      log "Skipping DB deps, because the DB doesn't exist."
    else
      requires 'db backed up'.with(env), 'migrate db'.with(env)
    end
  }
end

dep 'migrate db', :env, :template => 'benhoskings:task' do
  # requires 'benhoskings:maintenance page up'
  run {
    shell "bundle exec rake db:migrate db:autoupgrade tc:data:#{env} --trace RAILS_ENV=#{env}", :log => true
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
