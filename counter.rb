dep 'counter.theconversation.edu.au system', :app_user, :key

dep 'counter.theconversation.edu.au app', :env, :domain, :app_user, :app_root, :key do
  requires [
    'benhoskings:user setup'.with(:key => key),
    'geoip database'.with(:app_root => app_root),
    'ssl certificate'.with(env, domain, '*.theconversation.edu.au'),

    'benhoskings:rails app'.with(
      :env => env,
      :domain => domain,
      :username => app_user,
      :enable_https => 'yes',
      :data_required => 'no'
    ),

    # For the dw.theconversation.edu.au -> backup.tc-dev.net psql/ssh connection.
    'read-only db permissions'.with(YAML.load_file(app_root / 'config/database.yml')[env.to_s]['database'], 'dw.theconversation.edu.au', 'content_views')
  ]
end

dep 'counter.theconversation.edu.au packages' do
  requires [
    'benhoskings:running.nginx',
    'postgres.managed',
    'geoip.managed' # for geoip-c
  ]
end



dep 'counter.theconversation.edu.au dev' do
  requires [
    'geoip database'.with(:app_root => '.')
  ]
end
