dep "gpg key", :key_id do
  met? do
    shell("apt-key list").split("\n").collapse(/^pub/).find do |l|
      l[/\b#{Regexp.escape(key_id)}\b/]
    end
  end
  meet do
    shell("gpg --list-keys") # To initialize the config if it's not there
    shell("gpg --recv-keys #{key_id}")
    shell("apt-key add -", input: shell("gpg --export --armor #{key_id}"))
    shell("apt-get update")
  end
end
