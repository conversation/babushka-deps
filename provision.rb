dep 'provisioned' do
  requires [
    'packages',
    'crontab',
    'cron jobs',
    'asset backups'
  ]
  set :rails_root, '~/current'
end
