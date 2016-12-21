dep 'counter system', :app_user, :key, :env do
  requires [
    'postgres'.with('9.4'),
    'user setup for provisioning'.with("dw.theconversation.edu.au", key) # For DW loads from psql on the counter machine
  ]
end

dep 'counter env vars set', :domain

dep 'counter app', :env, :host, :domain, :app_user, :app_root, :key do
  requires [
    'geoip database'.with(:app_root => app_root),
    'ssl cert in place'.with(:domain => domain, :env => env),

    'db'.with(
      :env => env,
      :username => app_user,
      :root => app_root,
      :data_required => 'no'
    ),

    'sinatra app'.with(
      :app_name => 'counter',
      :env => env,
      :listen_host => host,
      :domain => domain,
      :username => app_user,
      :path => app_root
    )
  ]
end

dep 'counter packages' do
  requires [
    'counter common packages',
    'curl.lib',
    'running.nginx',
    'socat.bin', # for DB tunnelling
    'geoipupdate.bin' # for keeping maxmind geo databases up to date
  ]
end

dep 'counter dev' do
  requires [
    'counter common packages',
    'geoip database'.with(:app_root => '.'),
    'as database'.with(:app_root => '.')
  ]
end

dep 'counter common packages' do
  requires [
    'bundler.gem',
    'postgres.bin',
    'geoip.bin', # for geoip-c
    'libxml.lib', # for nokogiri
    'libxslt.lib', # for nokogiri
  ]
end
