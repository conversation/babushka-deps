# coding: utf-8

dep 'app deployed' do
  requires 'offsite backup.cloudfiles', '☕ & db'
end

dep '☕ & db', :template => 'benhoskings:task' do
  run { bundle_rake 'barista:brew db:migrate db:autoupgrade data:migrate tc:data:production' }
end
