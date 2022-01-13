class LocalContextsProject < Sequel::Model(:local_contexts_project)

  include ASModel

  corresponds_to JSONModel(:local_contexts_project)

  set_model_scope :global

  include Relationships

  # ArchivesSpaceService.loaded_hook do
  #   LocalContextsProject.define_relationship(:name => :local_contexts_project,
  #                               :contains_references_to_types => proc {LocalContextsProject.relationship_dependencies[:local_contexts_project]})
  # end

  def display_string
    "#{project_id} - #{project_name}"
  end

  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    jsons.zip(objs).each do |json, obj|
      json['display_string'] = obj.display_string
      # json['linked_record'] = {
      #   'ref' => obj.linked_record_uri
      # }
    end

    jsons
  end

  def linked_record_uri
    linked_record && linked_record.uri
  end

  private

  def linked_record
    @linked_record ||= related_records(:local_contexts_project)[0]
  end


end
