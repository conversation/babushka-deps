dep 'backup.tc-dev.net system', :app_user, :key do
  requires [
    'benhoskings:user setup for provisioning'.with("dw.#{app_user}", key) # For DW loads from psql on the backup machine
  ]
end

dep 'backup.tc-dev.net app'

dep 'backup.tc-dev.net packages' do
  requires [
    'postgres',
    'socat.bin' # for DB tunnelling
  ]
end
