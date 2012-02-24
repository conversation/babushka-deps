dep 'jobs.theconversation.edu.au system', :host_name, :app_user, :key

dep 'jobs.theconversation.edu.au app', :username, :db_name, :env do
  requires [
    'cronjobs'.with(env),
    'delayed job'.with(env),
    'postgres extension'.with(username, db_name, 'pg_trgm')
  ]
end

dep 'jobs.theconversation.edu.au packages' do
  requires [
    'benhoskings:running.nginx',
    'supervisor.managed',
    'jobs.theconversation.edu.au common packages'
  ]
end

dep 'jobs.theconversation.edu.au dev' do
  requires 'jobs.theconversation.edu.au common packages'
end

dep 'jobs.theconversation.edu.au common packages' do
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
