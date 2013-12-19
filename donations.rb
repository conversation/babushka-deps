dep 'donations system', :app_user, :key, :env

dep 'donations env vars set', :domain

dep 'donations app', :env, :host, :domain, :app_user, :app_root, :key do
  def db_name
    YAML.load_file(app_root / 'config/database.yml')[env.to_s]['database']
  end

  requires [
    'ssl cert in place'.with(:domain => domain, :env => env)
  ]

  if env == 'production'
    requires 'ssl cert in place'.with(:domain => 'donate.theconversation.edu.au', :env => env)
  end

  requires [
    'db'.with(
      :env => env,
      :username => app_user,
      :root => app_root,
      :data_required => 'no'
    ),

    'delayed job'.with(env, app_user),

    'rails app'.with(
      :app_name => 'donate',
      :env => env,
      :listen_host => host,
      :domain => domain,
      :username => app_user,
      :path => app_root
    )
  ]
end

dep 'donations packages' do
  requires [
    'postgres'.with('9.3'),
    'running.postfix',
    'running.nginx',
    'donations common packages'
  ]
end

dep 'donations dev' do
  requires 'donations common packages'
end

dep 'donations common packages' do
  requires [
    'bundler.gem',
    'postgres.bin',
    'libxml.lib', # for nokogiri
    'libxslt.lib', # for nokogiri
    'coffeescript.src' # for barista
  ]
end
