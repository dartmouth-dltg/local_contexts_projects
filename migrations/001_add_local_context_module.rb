require 'db/migrations/utils'

Sequel.migration do

  up do
    $stderr.puts("Adding Local Contexts Module plugin tables")

    create_table(:local_contexts_project) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      String :project_id, :null => false
      String :project_name, :null => false
      Integer :project_is_public

      apply_mtime_columns
    end

    create_table(:local_contexts_project_rlshp) do
      primary_key :id

      Integer :local_contexts_project_id
      Integer :accession_id
      Integer :archival_object_id
      Integer :digital_object_id
      Integer :digital_object_component_id
      Integer :resource_id
      Integer :aspace_relationship_position

      apply_mtime_columns(false)
    end

    alter_table(:local_contexts_project_rlshp) do
      add_foreign_key([:local_contexts_project_id], :local_contexts_project, :key => :id)
      add_foreign_key([:accession_id], :accession, :key => :id)
      add_foreign_key([:resource_id], :resource, :key => :id)
      add_foreign_key([:archival_object_id], :archival_object, :key => :id)
      add_foreign_key([:digital_object_id], :digital_object, :key => :id)
      add_foreign_key([:digital_object_component_id], :digital_object_component, :key => :id)
    end

  end

end
