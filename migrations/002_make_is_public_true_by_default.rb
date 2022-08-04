require 'db/migrations/utils'

Sequel.migration do

  up do
    $stderr.puts("Changing project_is_public to default to true")

    alter_table(:local_contexts_project) do
      set_column_default(:project_is_public, 1)
    end

  end

end
