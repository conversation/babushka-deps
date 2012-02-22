dep 'system provisioned for jobs.theconversation.edu.au', :host_name, :app_user, :password, :key do
  requires [
    'base system provisioned'.with(host_name, password, key),
    'benhoskings:running.nginx',
    'benhoskings:user auth setup'.with(app_user, password, key),
  ]
end

dep 'jobs.theconversation.edu.au provisioned', :username, :db_name, :env do
  requires [
    'jobs.theconversation.edu.au packages',
    'cronjobs'.with(env),
    'delayed job'.with(env),
    'postgres extension'.with(username, db_name, 'pg_trgm')
  ]
end

dep 'jobs.theconversation.edu.au packages' do
  requires 'jobs.theconversation.edu.au dev'
end

dep 'jobs.theconversation.edu.au dev' do
  requires [
    'bundler.gem',
    'benhoskings:postgres.managed',
    'libxml.managed', # for nokogiri
    'libxslt.managed', # for nokogiri
    'imagemagick.managed', # for paperclip
    'coffeescript.src', # for barista
    'postgresql-contrib.managed', # for search
    'tidy.managed' # for upmark
  ]
end
