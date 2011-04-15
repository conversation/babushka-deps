dep 'provisioned' do
  requires [
    'packages',
    'crontab',
    'cron jobs'
  ]
  set :rails_root, '~/current'
end
