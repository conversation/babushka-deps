dep 'jobs.theconversation.edu.au system', :app_user, :key

dep 'jobs.theconversation.edu.au app', :env, :domain, :app_user, :app_root, :key do
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
      :data_required => 'yes'
    )
  ]
end

dep 'jobs.theconversation.edu.au packages' do
  requires [
    'postgres'.with('9.2'),
    'curl.lib',
    'running.nginx',
    'jobs.theconversation.edu.au common packages'
  ]
end

dep 'jobs.theconversation.edu.au dev' do
  requires 'jobs.theconversation.edu.au common packages'
end

dep 'jobs.theconversation.edu.au common packages' do
  requires [
    'bundler.gem',
    'postgres.bin'.with('9.2'),
    'postgresql-contrib.lib', # for pg_trgm, for search
    'libxml.lib', # for nokogiri
    'libxslt.lib', # for nokogiri
    'imagemagick.bin', # for paperclip
    'coffeescript.src', # for barista
    'tidy.bin' # for upmark
  ]
end
