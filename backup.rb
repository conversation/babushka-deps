dep 'backup.tc-dev.net provisioned' do
  requires [
    'backup.tc-dev.net packages'
  ]
end

dep 'backup.tc-dev.net packages' do
  requires [
    'backup.tc-dev.net dev packages'
  ]
end

dep 'backup.tc-dev.net dev packages' do
  requires [
    'benhoskings:postgres.managed',
    'socat.managed' # for DB tunnelling
  ]
end
