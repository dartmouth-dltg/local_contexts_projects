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

  def validate
    super
    validates_unique(:project_id, :message => "local contexts project id not unique")
    validates_format(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i, :project_id, :message => "local contexts project invalid uuid")
  end

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
