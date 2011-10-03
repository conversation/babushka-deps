dep 'read-only db permissions' do
  requires 'benhoskings:postgres access'
  met? { shell "psql #{var(:db_name)} -c 'SELECT id FROM messages LIMIT 1'" }
  meet { sudo %Q{psql #{var(:db_name)} -c 'GRANT SELECT ON ALL TABLES IN SCHEMA "public" TO "#{var(:username)}"'}, as: 'postgres' }
end

dep 'postgres extension installed', :proc_name, :extension do
  met? {
    shell("psql postgres -t",
      as: 'postgres',
      input: "SELECT count(*) FROM pg_proc WHERE proname = '#{proc_name}'"
    ).strip.to_i > 0
  }
  meet {
    shell("psql postgres",
      as: 'postgres',
      input: (shell('pg_config --sharedir') / 'contrib' / extension).p.read
    )
  }
end
