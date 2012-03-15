dep 'restore db', :env, :app_user, :db_name, :app_root do

  requires 'benhoskings:existing postgres db'.with(app_user, db_name)

  met? {
    table_count = shell("psql #{db_name} -c '\\d'").scan(/\((\d+) rows?\)/).flatten.first

    table_count && table_count.to_i > 0
  }

  meet {
    shell({"RAILS_ENV" => env}, "bundle exec rake db:restore", :cd => app_root)
  }
end
