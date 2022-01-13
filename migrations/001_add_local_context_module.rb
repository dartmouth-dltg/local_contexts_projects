require 'db/migrations/utils'

Sequel.migration do

  up do
    $stderr.puts("Adding Local Contexts Module plugin tables")

    create_table(:local_context_project) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      String :project_id, :null => false
      String :project_name, :null => false
      Integer :project_is_public

      apply_mtime_columns
    end

    alter_table(:local_context_project) do
      add_foreign_key([:accession_id], :accession, :key => :id)
      add_foreign_key([:resource_id], :resource, :key => :id)
      add_foreign_key([:archival_object_id], :archival_object, :key => :id)
      add_foreign_key([:digital_object_id], :digital_object, :key => :id)
    end

  end

end
