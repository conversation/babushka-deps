dep 'jobs system', :app_user, :key, :env

dep 'jobs env vars set', :domain

dep 'jobs app', :env, :host, :domain, :app_user, :app_root, :key do
  def database_name
    config = YAML.load_file(root / 'config/database.yml').tap do |config|
      unmeetable! "There's no database.yml entry for the #{env} environment." if config.nil?
    end

    if database = config.dig(env.to_s, 'database')
      database
    elsif url = config.dig(env.to_s, 'url')
      URI.parse(url).path.gsub(/^\//, '')
    else
      unmeetable! "There's no database or url defined in the database.yml file for the #{env} environment"
    end
  end

  requires [
    'postgres extension'.with(app_user, database_name, 'pg_trgm'),
    'ssl cert in place'.with(:domain => domain, :env => env),
  ]

  requires [
    'db'.with(
      :env => env,
      :username => app_user,
      :root => app_root,
      :data_required => (env == 'production' ? 'yes' : 'no')
    ),

    'delayed job'.with(
      :env => env,
      :user => app_user
    ),

    'rails app'.with(
      :app_name => 'jobs',
      :env => env,
      :listen_host => host,
      :domain => domain,
      :username => app_user,
      :path => app_root
    )
  ]
end

dep 'jobs packages' do
  requires [
    'postgres',
    'curl.lib',
    'running.nginx',
    'jobs common packages'
  ]
end

dep 'jobs dev' do
  requires 'jobs common packages'
end

dep 'jobs common packages' do
  requires [
    'bundler.gem',
    'postgres.bin',
    'postgresql-contrib.lib', # for pg_trgm, for search
    'libxml.lib', # for nokogiri
    'libxslt.lib', # for nokogiri
    'imagemagick.bin', # for paperclip
    'coffeescript.bin', # for barista
    'tidy.bin' # for upmark
  ]
end
