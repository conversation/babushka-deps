dep 'provisioned' do
  requires [
    'libxml.managed', # for nokogiri
    'libxslt.managed',  # for nokogiri
    'imagemagick.managed', # for paperclip
    'coffeescript.src', # for barista
    'prod data',
    'cron jobs',
    'asset backups'
  ]
end
