dep 'backup.tc-dev.net system', :host_name, :app_user, :password, :key do
  requires [
    'benhoskings:user auth setup'.with("dw.#{app_user}", password, key) # For DW loads from psql on the backup machine
  ]
end

dep 'backup.tc-dev.net app'

dep 'backup.tc-dev.net packages' do
  requires [
    'benhoskings:postgres.managed',
    'socat.managed' # for DB tunnelling
  ]
end
