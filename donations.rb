dep 'donations system', :app_user, :key, :env

dep 'donations app', :env, :host, :domain, :app_user, :app_root, :key do
  def db_name
    YAML.load_file(app_root / 'config/database.yml')[env.to_s]['database']
  end

  requires [
    'delayed job'.with(env, app_user),

    'ssl cert in place'.with(:domain => domain, :cert_name => 'donate.theconversation.edu.au'),

    'rack app'.with(
      :app_name => 'donate',
      :env => env,
      :listen_host => host,
      :domain => domain,
      :username => app_user,
      :path => app_root
    ),

    'db'.with(
      :env => env,
      :username => app_user,
      :root => app_root,
      :data_required => 'no'
    )
  ]
end

dep 'donations packages' do
  requires [
    'postgres'.with('9.2'),
    'curl.lib',
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
