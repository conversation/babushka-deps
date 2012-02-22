dep 'system provisioned for theconversation.edu.au', :host_name, :app_user, :password, :key do
  requires [
    'base system provisioned'.with(host_name, password, key),
    'benhoskings:running.nginx',
    'benhoskings:user auth setup'.with(app_user, password, key),
    'benhoskings:user auth setup'.with("mobwrite.#{app_user}", password, key),
  ]
end

dep 'theconversation.edu.au provisioned', :env, :domain, :app_user, :key, :app_root do
  requires [
    'benhoskings:user setup'.with(key: key),
    'theconversation.edu.au packages',
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

dep 'theconversation.edu.au dev' do
  requires [
    'benhoskings:postgres.managed',
    'theconversation.edu.au dev packages',
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
    'bundler.gem',
    'benhoskings:postgres.managed',
    'aspell dictionary.managed',
    'coffeescript.src', # for barista
    'imagemagick.managed', # for paperclip
    'libxml.managed', # for nokogiri
    'libxslt.managed', # for nokogiri
    'memcached.managed', # for fragment caching
    'phantomjs' # for js testing
  ]
end
