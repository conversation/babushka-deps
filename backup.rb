dep 'system provisioned for backup.tc-dev.net', :host_name, :app_user, :password, :key do
  requires [
    'base system provisioned'.with(host_name, password, key),
    "#{app_user} packages",
    'benhoskings:user auth setup'.with(app_user, password, key), # For `rake db:production:pull`
    'benhoskings:user auth setup'.with("dw.#{app_user}", password, key) # For DW loads from psql on the backup machine
  ]
end

dep 'backup.tc-dev.net provisioned' do
  requires [
    'backup.tc-dev.net packages'
  ]
end

dep 'backup.tc-dev.net packages' do
  requires [
    'backup.tc-dev.net dev packages'
  ]
end

dep 'backup.tc-dev.net dev packages' do
  requires [
    'benhoskings:postgres.managed',
    'socat.managed' # for DB tunnelling
  ]
end
