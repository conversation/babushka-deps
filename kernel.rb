dep 'kernel running', :version do
  met? {
    running_version = shell('uname -r')

    if running_version[/xen|virtual/]
      log "Can't upgrade a VPS' kernel from within the instance - skipping version check."
      true
    elsif running_version.to_version >= version.to_s
      log_ok "The running kernel is #{running_version} (>= #{version})."
    else
      unmeetable! "The running kernel is #{running_version} (expecting >= #{version})."
    end
  }
end
