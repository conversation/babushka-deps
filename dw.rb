dep 'dw system', :app_user, :key, :env

dep 'dw app', :env, :host, :domain, :app_user, :app_root, :key do
  requires [
    'existing db'.with(
      :username => app_user,
      :db_name => "tc_dw_#{env}"
    ),

    'rack app'.with(
      :app_name => 'dw',
      :env => env,
      :listen_host => host,
      :enable_https => 'no',
      :domain => domain,
      :username => app_user,
      :path => app_root
    )
  ]
end

dep 'dw packages' do
  requires [
    'postgres',
    'curl.lib',
    'running.nginx',
    'dw common packages'
  ]
end

dep 'dw dev' do
  requires 'dw common packages'
end

dep 'dw common packages' do
  requires [
    'postgres.bin',
    'socat.bin' # for DB tunnelling
  ]
end
