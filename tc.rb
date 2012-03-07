dep 'theconversation.edu.au system', :app_user, :key do
  requires [
    'benhoskings:user setup for provisioning'.with("mobwrite.#{app_user}", key),
  ]
end

dep 'theconversation.edu.au app', :env, :domain, :app_user, :app_root, :key do
  requires [
    'benhoskings:user setup'.with(:key => key),
    'geoip database'.with(:app_root => app_root),
    'cronjobs'.with(env),
    'delayed job'.with(env),
    'ssl certificate'.with(env, domain, 'theconversation.edu.au'),

    'benhoskings:rails app'.with(
      :env => env,
      :domain => domain,
      :username => app_user,
      :domain_aliases => 'theconversation.com theconversation.org.au conversation.edu.au',
      :enable_https => 'yes',
      :data_required => 'yes'
    ),

    # For the dw.theconversation.edu.au -> backup.tc-dev.net psql/ssh connection.
    'read-only db permissions'.with(YAML.load_file(app_root / 'config/database.yml')[env.to_s]['database'], 'dw.theconversation.edu.au', 'content')
  ]
end

dep 'theconversation.edu.au packages' do
  requires [
    'benhoskings:running.nginx',
    'supervisor.managed',
    'theconversation.edu.au common packages'
  ]
end

dep 'theconversation.edu.au dev' do
  requires [
    'theconversation.edu.au common packages',
    'phantomjs', # for js testing
    'geoip database'.with(:app_root => '.')
  ]
end

dep 'theconversation.edu.au common packages' do
  requires [
    'bundler.gem',
    'postgres.managed',
    'geoip.managed', # for geoip-c
    'aspell dictionary.managed',
    'coffeescript.src', # for barista
    'imagemagick.managed', # for paperclip
    'libxml.managed', # for nokogiri
    'libxslt.managed', # for nokogiri
    'memcached.managed' # for fragment caching
  ]
end
