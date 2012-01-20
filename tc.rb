dep 'theconversation.edu.au provisioned', :env, :app_root do
  requires [
    'theconversation.edu.au packages',
    'cronjobs'.with(env),
    'delayed job'.with(env),
    'geoip database'.with(app_root: app_root),

    # For the dw.theconversation.edu.au -> backup.tc-dev.net psql/ssh connection.
    'read-only db permissions'.with("tc_#{env}", 'dw.theconversation.edu.au', 'content')
  ]
end

dep 'theconversation.edu.au dev' do
  requires [
    'benhoskings:postgres.managed',
    'theconversation.edu.au dev packages',
    'geoip database'.with(app_root: '.')
  ]
end

dep 'theconversation.edu.au packages' do
  requires [
    'theconversation.edu.au dev packages',
    'supervisor.managed'
  ]
end

dep 'theconversation.edu.au dev packages' do
  requires [
    'libxml.managed', # for nokogiri
    'libxslt.managed', # for nokogiri
    'imagemagick.managed', # for paperclip
    'coffeescript.src', # for barista
    'geoip.managed' # for geoip-c
  ]
end