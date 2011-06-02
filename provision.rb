dep 'provisioned' do
  requires [
    'packages',
    'cronjobs'
  ]
  set :rails_root, '~/current'
end
