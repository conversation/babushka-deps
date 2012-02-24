dep 'theconversation.edu.au system', :host_name, :app_user, :password, :key do
  requires [
    'benhoskings:user setup for provisioning'.with("mobwrite.#{app_user}", key),
  ]
end

dep 'theconversation.edu.au app', :env, :domain, :app_user, :key, :app_root do
  requires [
    'benhoskings:user setup'.with(key: key),
    'geoip database'.with(app_root: app_root),
    'cronjobs'.with(env),
    'delayed job'.with(env),
    'ssl certificate'.with(env, domain),

    'benhoskings:rails app'.with(
      env: env,
      domain: domain,
      username: app_user,
      domain_aliases: 'theconversation.com theconversation.org.au conversation.edu.au',
      enable_https: 'yes',
      data_required: 'yes'
    ),

    # For the dw.theconversation.edu.au -> backup.tc-dev.net psql/ssh connection.
    'read-only db permissions'.with("tc_#{env}", 'dw.theconversation.edu.au', 'content')
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
    'geoip database'.with(app_root: '.')
  ]
end

dep 'theconversation.edu.au common packages' do
  requires [
    'bundler.gem',
    'benhoskings:postgres.managed',
    'aspell dictionary.managed',
    'coffeescript.src', # for barista
    'imagemagick.managed', # for paperclip
    'libxml.managed', # for nokogiri
    'libxslt.managed', # for nokogiri
    'memcached.managed', # for fragment caching
  ]
end
