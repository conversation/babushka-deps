dep 'our apt source' do
  requires 'apt source'.with(:uri => 'http://apt.tc-dev.net/', :repo => 'main')
end
