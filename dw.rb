dep 'dw system', :app_user, :key

dep 'dw app', :env, :host, :domain, :app_user, :app_root, :key do
  requires [
    'benhoskings:rack app'.with(
      :env => env,
      :listen_host => host,
      :domain => domain,
      :username => app_user,
      :path => app_root
    ),

    'benhoskings:existing postgres db'.with(
      :username => app_user,
      :db_name => "tc_dw_#{env}"
    )
  ]
end

dep 'dw packages' do
  requires [
    'postgres'.with('9.2'),
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
    'postgres.bin'.with('9.2'),
    'socat.bin' # for DB tunnelling
  ]
end
