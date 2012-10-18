dep 'ci packages' do
  requires 'openjdk-6-jdk'
end

dep 'openjdk-6-jdk', :template => 'bin' do
  provides 'java', 'javac'
end
