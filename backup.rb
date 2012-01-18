dep 'backup.tc-dev.net provisioned', :env, :app_root do
  requires [
    'backup.tc-dev.net packages'
  ]
end

dep 'backup.tc-dev.net dev packages' do
  requires [
    'socat.managed' # for DB tunnelling
  ]
end
