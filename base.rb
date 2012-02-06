dep 'system provisioned', :domain, :app_user, :password, :key do
  requires [
    'base system provisioned'.with(domain, password, key),
    'benhoskings:running.nginx',
    "#{app_user} packages",
    'users setup'.with(app_user, password, key)
  ]
end

dep 'base system provisioned', :domain, :password, :key do
  requires [
    'benhoskings:user setup'.with(key: key),
    'benhoskings:system'.with(host_name: domain),
    'benhoskings:lamp stack removed',
    'benhoskings:postfix removed',
    'benhoskings:postgres.managed'
  ]
end

dep 'users setup', :domain, :password, :key do
  requires 'benhoskings:user auth setup'.with(domain, password, key)
  requires 'benhoskings:user auth setup'.with("mobwrite.#{domain}", password, key)
  requires 'benhoskings:user auth setup'.with("chat.#{domain}", password, key)
end
