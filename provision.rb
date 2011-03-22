dep 'provisioned' do
  requires [
    'packages',
    'cron jobs',
    'asset backups'
  ]
end
