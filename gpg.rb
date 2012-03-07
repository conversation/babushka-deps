dep 'gpg key', :key_id do
  met? {
    shell('apt-key list').split("\n").collapse(/^pub/).find {|l|
      l[/\b#{Regexp.escape(key_id)}\b/]
    }
  }
  meet {
    shell('gpg --list-keys') # To initialize the config if it's not there
    shell("gpg --recv-keys #{key_id}")
    shell('apt-key add -', :input => shell("gpg --export --armor #{key_id}"))
  }
end
