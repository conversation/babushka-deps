dep 'theconversation.edu.au packages' do
  requires [
    'libxml.managed', # for nokogiri
    'libxslt.managed', # for nokogiri
    'imagemagick.managed', # for paperclip
    'coffeescript.src', # for barista
    'supervisor.managed'
  ]
end

dep 'jobs.theconversation.edu.au packages' do
  requires [
    'imagemagick.managed', # for paperclip
    'postgresql-contrib-9.0.managed', # for search
    'tidy.managed' # for upmark
  ]
end
