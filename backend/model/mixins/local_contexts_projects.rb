module LocalContextsProjects

  def self.included(base)
    base.include(Relationships)

    # base.define_relationship(:name => :local_contexts_project_link,
    #                          :json_property => 'local_contexts_project',
    #                          :contains_references_to_types => proc {[LocalContextsProject]})


    # base.def_nested_record(:the_property => :local_contexts_project,
    #                        :contains_records_of_type => :local_contexts_project,
    #                        :corresponding_to_association  => :local_contexts_project,
    #                        :is_array => false)
  end

end
