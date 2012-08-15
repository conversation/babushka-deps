dep 'counter.theconversation.edu.au system', :app_user, :key do
  requires [
    'postgres',
    'benhoskings:user setup for provisioning'.with("dw.theconversation.edu.au", key) # For DW loads from psql on the counter machine
  ]
end

dep 'counter.theconversation.edu.au app', :env, :domain, :app_user, :app_root, :key do
  requires [
    'geoip database'.with(:app_root => app_root),
    'ssl certificate'.with(env, domain, '*.theconversation.edu.au'),

    'benhoskings:rails app'.with(
      :env => env,
      :domain => domain,
      :username => app_user,
      :enable_https => 'yes',
      :data_required => 'no'
    ),

    # Replace the default config with our own.
    'vhost enabled.nginx'.with(
      :app_name => 'counter',
      :domain => domain,
      :path => app_root,
      :enable_https => 'yes',
      :force_https => 'no'
    ),

    # For the dw.theconversation.edu.au -> backup.tc-dev.net psql/ssh connection.
    'read-only db access'.with(
      :db_name => YAML.load_file(app_root / 'config/database.yml')[env.to_s]['database'],
      :username => 'dw.theconversation.edu.au',
      :check_table => 'content_views'
    )
  ]
end

dep 'counter.theconversation.edu.au packages' do
  requires [
    'counter.theconversation.edu.au common packages',
    'curl.lib',
    'running.nginx',
    'geoip.bin', # for geoip-c
    'libxml.lib', # for nokogiri
    'libxslt.lib', # for nokogiri
    'socat.bin' # for DB tunnelling
  ]
end



dep 'counter.theconversation.edu.au dev' do
  requires [
    'counter.theconversation.edu.au common packages',
    'geoip database'.with(:app_root => '.')
  ]
end

dep 'counter.theconversation.edu.au common packages' do
  requires [
    'postgres.bin'
  ]
end
