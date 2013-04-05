dep 'counter system', :app_user, :key do
  requires [
    'postgres'.with('9.2'),
    'benhoskings:user setup for provisioning'.with("dw.theconversation.edu.au", key) # For DW loads from psql on the counter machine
  ]
end

dep 'counter app', :env, :host, :domain, :app_user, :app_root, :key do
  requires [
    'geoip database'.with(:app_root => app_root),
    'ssl cert in place'.with(:domain => domain, :cert_name => '*.theconversation.edu.au'),

    'rails app'.with(
      :app_name => 'counter',
      :env => env,
      :listen_host => host,
      :domain => domain,
      :username => app_user,
      :path => app_root,
      :data_required => 'no'
    ),

    # For the dw.theconversation.edu.au -> backup.tc-dev.net psql/ssh connection.
    'db access'.with(
      :db_name => YAML.load_file(app_root / 'config/database.yml')[env.to_s]['database'],
      :username => 'dw.theconversation.edu.au',
      :check_table => 'content_views'
    )
  ]
end

dep 'counter packages' do
  requires [
    'counter common packages',
    'curl.lib',
    'running.nginx',
    'socat.bin' # for DB tunnelling
  ]
end



dep 'counter dev' do
  requires [
    'counter common packages',
    'geoip database'.with(:app_root => '.')
  ]
end

dep 'counter common packages' do
  requires [
    'postgres.bin',
    'geoip.bin', # for geoip-c
    'libxml.lib', # for nokogiri
    'libxslt.lib', # for nokogiri
  ]
end
