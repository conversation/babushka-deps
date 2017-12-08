# This dep overrides `common:app bundled` to ensure bundler is configured
# without binstubs.
dep "app bundled", :root, :env do
  requires_when_unmet Dep("current dir:packages")
  met? do
    if !(root / "Gemfile").exists?
      log "No Gemfile - skipping bundling."
      true
    else
      shell? "bundle check", cd: root, log: true
    end
  end
  meet do
    # Ensure we aren't installing binstubs.
    shell "bundle config --delete bin", cd: root

    install_args = %w[development test].include?(env) ? "" : "--deployment --without 'development test'"

    unless shell("bundle install #{install_args} | grep -v '^Using '", cd: root, log: true)
      confirm("Try a `bundle update`", default: "n") do
        shell "bundle update", cd: root, log: true
      end
    end
  end
end
