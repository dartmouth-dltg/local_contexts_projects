require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:local_contexts_project) do
      add_column(:project_api_key, String, :default => nil)
    end
  end

end
