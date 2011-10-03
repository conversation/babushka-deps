dep 'read-only db permissions' do
  requires 'benhoskings:postgres access'
  met? { shell "psql #{var(:db_name)} -c 'SELECT id FROM messages LIMIT 1'" }
  meet { sudo %Q{psql #{var(:db_name)} -c 'GRANT SELECT ON ALL TABLES IN SCHEMA "public" TO "#{var(:username)}"'}, as: 'postgres' }
end

dep 'postgres extension installed', :username, :db_name, :proc_name, :extension do
  def set_language_trust val
    shell "psql #{db_name}",
      as: 'postgres',
      input: "UPDATE pg_language SET lanpltrusted = '#{val ? 't' : 'f'}' WHERE lanname = 'c'"
  end

  met? {
    shell("psql #{db_name} -t",
      as: 'postgres',
      input: "SELECT count(*) FROM pg_proc WHERE proname = '#{proc_name}'"
    ).strip.to_i > 0
  }

  before { set_language_trust true }
  meet {
    shell "psql #{db_name}",
      as: username,
      input: (shell('pg_config --sharedir') / 'contrib' / extension).p.read
  }
  before { set_language_trust false }
end
