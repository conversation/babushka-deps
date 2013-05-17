dep 'kernel running', :version do
  met? {
    running_version = shell('uname -r').to_version
    (running_version >= version.to_s).tap {|result|
      log "The running kernel is #{running_version} (expecting >= #{version}).", :as => result
    }
  }
end
