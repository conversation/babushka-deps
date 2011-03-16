dep 'mobwrite' do
  requires [
    'mobwrite daemon.supervisor',
    'mobwrite gateway.supervisor'
  ]
end

dep 'mobwrite daemon.supervisor' do
  requires 'mobwrite repo'
  command "python mobwrite_daemon.py"
  user "mobwrite.theconversation.edu.au"
  directory "/srv/http/#{user}/current/daemon"
  met? {
    !shell("ps aux").split("\n").grep(/#{Regexp.escape(command)}$/).empty?
  }
end

dep 'mobwrite gateway.supervisor' do
  requires 'mobwrite repo', 'gunicorn.pip'
  command "gunicorn gateway:application"
  user "mobwrite.theconversation.edu.au"
  directory "/srv/http/#{user}/current/daemon"
  met? {
    (shell("curl -I localhost:8000") || '').val_for('Server')['gunicorn']
  }
end

dep 'gunicorn.pip' do
  installs 'gunicorn'
end

dep 'pip.managed' do
  installs 'python-pip'
end

dep 'mobwrite repo' do
  met? {
    "~/current/daemon".p.directory?
  }
  meet {
    git "git://github.com/conversation/mobwrite.git", to: "~/current"
  }
end
