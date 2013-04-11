dep 'jobs system', :app_user, :key, :env

dep 'jobs app', :env, :host, :domain, :app_user, :app_root, :key do
  def db_name
    YAML.load_file(app_root / 'config/database.yml')[env.to_s]['database']
  end

  requires [
    'delayed job'.with(env, app_user),
    'postgres extension'.with(app_user, db_name, 'pg_trgm'),
    'ssl cert in place'.with(:domain => domain, :cert_name => 'jobs.theconversation.edu.au'),
    'benhoskings:rails app'.with(
      :env => env,
      :listen_host => host,
      :domain => domain,
      :username => app_user,
      :path => app_root,
      :enable_https => 'yes',
      :data_required => 'yes'
    )
  ]
end

dep 'jobs packages' do
  requires [
    'postgres'.with('9.1.9'),
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
    'postgres.bin'.with('9.1.9'),
    'postgresql-contrib.lib', # for pg_trgm, for search
    'libxml.lib', # for nokogiri
    'libxslt.lib', # for nokogiri
    'imagemagick.bin', # for paperclip
    'coffeescript.src', # for barista
    'tidy.bin' # for upmark
  ]
end
