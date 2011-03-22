dep 'provisioned' do
  requires [
    'packages',
    'cron jobs',
    'asset backups'
  ]
  set :rails_root, '~/current'
end
