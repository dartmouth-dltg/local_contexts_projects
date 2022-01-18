class LocalContextsProject < Sequel::Model(:local_contexts_project)

  include ASModel

  corresponds_to JSONModel(:local_contexts_project)

  set_model_scope :global

  include Relationships

  define_relationship(:name => :local_contexts_project,
                      :json_property => 'linked_records',
                      :contains_references_to_types => proc {[
                        Accession, ArchivalObject, Resource, DigitalObject, DigitalObjectComponent
                      ]})

  def display_string
    "#{project_id} : #{project_name}"
  end

  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    jsons.zip(objs).each do |json, obj|
      json['display_string'] = obj.display_string
    end

    jsons
  end

end
