dep 'theconversation.edu.au provisioned', :env do
  requires [
    'theconversation.edu.au packages',
    'cronjobs'.with(env),
    'delayed job'.with(env)
  ]
end

dep 'theconversation.edu.au packages' do
  requires [
    'theconversation.edu.au dev',
    'supervisor.managed'
  ]
end

dep 'theconversation.edu.au dev' do
  requires [
    'libxml.managed', # for nokogiri
    'libxslt.managed', # for nokogiri
    'imagemagick.managed', # for paperclip
    'coffeescript.src', # for barista
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
    'theconversation.edu.au dev', # The same packages the main app uses
    'postgresql-contrib.managed', # for search
    'tidy.managed' # for upmark
  ]
end
