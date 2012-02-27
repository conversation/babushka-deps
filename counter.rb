dep 'counter.theconversation.edu.au system', :host_name, :app_user, :key

dep 'counter.theconversation.edu.au app', :env, :domain, :app_user, :key, :app_root do
  requires [
    'benhoskings:user setup'.with(key: key),
    'geoip database'.with(app_root: app_root),
    'ssl certificate'.with(env, domain),

    'benhoskings:rails app'.with(
      env: env,
      domain: domain,
      username: app_user,
      enable_https: 'no',
      data_required: 'yes'
    ),

    # For the dw.theconversation.edu.au -> backup.tc-dev.net psql/ssh connection.
    'read-only db permissions'.with("tc_#{env}", 'dw.theconversation.edu.au', 'content')
  ]
end

dep 'counter.theconversation.edu.au packages' do
  requires [
    'benhoskings:running.nginx',
    'benhoskings:postgres.managed',
  ]
end



dep 'counter.theconversation.edu.au dev' do
  requires [
    'geoip database'.with(app_root: '.'),
  ]
end
