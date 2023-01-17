require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:local_contexts_project_rlshp) do
      add_column(:suppressed, Integer, :null => false, :default => 0)
    end
  end

end
