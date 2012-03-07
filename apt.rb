dep 'our apt source' do
  requires 'apt source'.with(:uri => 'http://apt.tc-dev.net/', :repo => 'main')
  requires 'gpg key'.with('B6D8A3F9')
end
