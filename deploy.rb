dep 'assets precompiled during deploy', :env, :deploying, :template => 'task' do
  run {
    shell "bundle exec rake assets:precompile RAILS_ENV=#{env}"
  }
end

dep 'upload assets', :env, :deploying do
  met? {
    shell? "bundle exec rake tc:assets:upload_required RAILS_ENV=#{env}"
  }
  meet {
    shell "bundle exec rake tc:assets:upload RAILS_ENV=#{env}", :log => true
  }
end

dep 'db backed up', :env, :db_name do
  env.default!(ENV['RAILS_ENV'] || 'production')
  db_name.default!(
    'config/database.yml'.p.yaml[env.to_s]['database']
  )
  setup {
    if env != 'production'
      log "Skipping DB backup on #{env}."
    else
      requires 'offsite backup.cloudfiles'.with(:db_name => db_name)
    end
  }
end

dep 'cache cleared' do
  met? {
    shell("git clean -ndx public/*.html public/pages/*.html").empty?
  }
  meet {
    shell "git clean -fdx public/*.html public/pages/*.html", :log => true
  }
end
