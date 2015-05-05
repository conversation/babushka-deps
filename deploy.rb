require 'fileutils'

def on_standby?
  psql_output = shell?("psql tc_#{env} -t -c 'SHOW transaction_read_only'")
  !psql_output.nil? && psql_output['on']
end

dep 'assets precompiled during deploy', :env, :deploying, :template => 'task' do
  run {
    shell "bundle exec rake assets:precompile RAILS_ENV=#{env}"
  }
end

dep 'upload assets', :env, :deploying do
  met? {
    shell? "bundle exec rake tc:assets:upload_required RAILS_ENV=#{env}"
  }
  meet {
    shell "bundle exec rake tc:assets:upload RAILS_ENV=#{env}", :log => true
  }
end

dep 'cache cleared' do
  met? {
    shell("git clean -ndx public/*.html public/pages/*.html").empty?
  }
  meet {
    shell "git clean -fdx public/*.html public/pages/*.html", :log => true
  }
end

dep 'marked on newrelic.task', :ref, :env do
  requires 'app bundled'.with('.', 'development')
  run {
    # Some of our apps store the newrelic config file in a template that is copied]
    # into position in production.
    if 'config/newrelic.yml'.p.exists?
      shell "bundle exec newrelic deployments -e #{env} -r #{shell("git rev-parse --short #{ref}")}"
    elsif 'config/newrelic.yml.template'.p.exists?
      FileUtils.cp('config/newrelic.yml.template', 'config/newrelic.yml')
      shell "bundle exec newrelic deployments -e #{env} -r #{shell("git rev-parse --short #{ref}")}"
      FileUtils.rm('config/newrelic.yml')
    else
      log_ok "newrelic config not found, skipping"
    end
  }
end

dep 'marked on bugsnag.task', :ref, :env do
  requires 'app bundled'.with('.', 'development')
  run {
    if 'config/initializers/bugsnag.rb'.p.exists?
      log_shell "Notifying bugsnag", "bundle exec rake bugsnag:deploy BUGSNAG_REVISION=#{shell("git rev-parse --short #{ref}")} BUGSNAG_RELEASE_STAGE=#{env}"
    else
      log_ok "bugsnag config not found, skipping"
    end
  }
end

# This dep ensures that we only enable newrelic monitoring on production
# and not standby. Prevents us from having to pay for two servers
dep "set up newrelic configuration", :env do
  setup {
    if (env == "production" && !on_standby?) || env == "staging"
      log "Writing newrelic config"
      if File.file?('newrelic.yml.template')
        FileUtils.cp('config/newrelic.yml.template', 'config/newrelic.yml')
      end
      FileUtils.cp('newrelic.js.template', 'newrelic.js') if File.file?('newrelic.js.template')
      true
    else
      log "Deleting newrelic config"
      FileUtils.rm('config/newrelic.yml', :force => true)
      FileUtils.rm('newrelic.js', :force => true)
      true
    end
  }
end
