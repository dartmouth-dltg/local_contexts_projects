module LocalContextsProjects

  def self.included(base)

    base.include(Relationships)

    base.define_relationship(:name => :local_contexts_project,
                             :json_property => 'local_contexts_projects',
                             :contains_references_to_types => proc {[LocalContextsProject]})

  end
  
end
