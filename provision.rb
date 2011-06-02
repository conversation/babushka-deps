dep 'provisioned' do
  requires [
    'packages',
    'crontab',
    'cronjobs'
  ]
  set :rails_root, '~/current'
end
