dep 'analytics system', :app_user, :key, :env

dep 'analytics env vars set', :domain

dep 'analytics app', :env, :host, :domain, :app_user, :app_root, :key do

  requires [
    'ssl cert in place'.with(:domain => domain, :env => env)
  ]

  if env == 'production'
    requires 'ssl cert in place'.with(:domain => 'analytics.theconversation.com', :env => env)
  end

  requires [
    'db'.with(
      :env => env,
      :username => app_user,
      :root => app_root,
      :data_required => 'no'
    ),

    'rails app'.with(
      :app_name => 'analytics',
      :env => env,
      :listen_host => host,
      :domain => domain,
      :username => app_user,
      :path => app_root,
      :threads => 8
    )
  ]
end

dep 'analytics packages' do
  requires [
    'postgres'.with('9.6'), # not strictly required, but user setup expects it it be installed
    'running.nginx',
    'analytics common packages'
  ]
end

dep 'analytics dev' do
  requires 'analytics common packages'
end

dep 'analytics common packages' do
  requires [
    'bundler.gem',
    'libxml.lib', # for nokogiri
    'libxslt.lib', # for nokogiri
    'sasl.lib', # for memcached gem
    'coffeescript.bin' # for barista
  ]
end
