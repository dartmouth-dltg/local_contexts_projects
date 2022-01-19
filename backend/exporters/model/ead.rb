class EADModel < ASpaceExport::ExportModel

  # we add local_contexts_projects to the resolve list
  RESOLVE = ['subjects', 'linked_agents', 'digital_object', 'top_container', 'top_container::container_profile', 'local_contexts_projects']

  def local_contexts_project
    self.local_contexts_project
  end
end
