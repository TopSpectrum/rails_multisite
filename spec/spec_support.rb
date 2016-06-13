def clear_state

  klass.clear_settings!

  ActiveRecord::Base.connection_handler = DEFAULT_HANDLER

end

def execute_for_database ( database_name, sql )

  RailsMultisite::ConnectionManagement.with_connection database_name do

    ActiveRecord::Base.connection.raw_connection.execute sql rescue nil

  end

end

def create_table_in_database ( database_name, table, columns )

  sql = "create table if not exists #{ table }(id INTEGER PRIMARY KEY AUTOINCREMENT, #{ columns })"

  execute_for_database database_name, sql

end

def drop_table_in_database ( database_name, table )

  sql = "drop table #{ table }"

  execute_for_database database_name, sql

end

def toogle_table_in_database ( database_name, table, argument )

  if argument

    create_table_in_database database_name, table, argument

  else

    drop_table_in_database database_name, table

  end

end
