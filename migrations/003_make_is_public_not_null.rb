require 'db/migrations/utils'

Sequel.migration do

  up do
    $stderr.puts("Changing project_is_public to not null")

    alter_table(:local_contexts_project) do
      set_column_not_null(:project_is_public)
    end

  end

end
