dep 'system provisioned', :domain, :app_user, :password, :key do
  requires [
    'base system provisioned'.with(domain, password, key),
    'benhoskings:running.nginx',
    "#{domain} packages",
    'users setup'.with(domain, password, key)
  ]
end

dep 'base system provisioned', :domain, :password, :key do
  requires [
    'benhoskings:ruby.src'.with(version: '1.9.3', patchlevel: 'p0'),
    'benhoskings:user setup'.with(password: password, key: key),
    'benhoskings:system'.with(hostname: domain),
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
