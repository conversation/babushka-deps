dep 'provisioned' do
  requires [
    'packages',
    'cronjobs',
    'delayed job'
  ]
  set :rails_root, '~/current'
end
