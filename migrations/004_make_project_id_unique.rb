require 'db/migrations/utils'

Sequel.migration do

  up do
    $stderr.puts("Ensuring project id is unique")

    alter_table(:local_contexts_project) do
      add_unique_constraint(:project_id, :name => "local_contexts_project_id_uniq")
    end

  end

end
