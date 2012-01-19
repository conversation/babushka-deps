dep 'dw.theconversation.edu.au provisioned', :env, :app_root do
  requires [
    'dw.theconversation.edu.au packages',
    'cronjobs'.with(env)
  ]
end

dep 'dw.theconversation.edu.au packages' do
  requires [
    'dw.theconversation.edu.au dev packages'
  ]
end

dep 'dw.theconversation.edu.au dev packages' do
  requires [
    'socat.managed' # for DB tunnelling
  ]
end
