require 'db/migrations/utils'

Sequel.migration do

  up do
    self[:local_contexts_project].update(:system_mtime => Time.now)
  end

end
