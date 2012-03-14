dep 'app env vars set', :env do
  requires [
    'env var set'.with('RACK_ENV', env),
    'env var set'.with('RAILS_ENV', env),
    'env var set'.with('NODE_ENV', env)
  ]
end

dep 'env var set', :key, :value do
  met? {
    login_shell("echo $#{key}") == value
  }
  meet {
    "~/.zshenv".p.append("export #{key}=#{value}\n")
  }
end
