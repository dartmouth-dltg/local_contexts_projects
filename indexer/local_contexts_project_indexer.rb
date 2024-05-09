class IndexerCommon

  @@record_types << :local_contexts_project
  @@global_types << :local_contexts_project

  @local_contexts_resolves = [
    'ancestors',
    'ancestors::local_contexts_projects',
    'instances::digital_object::local_contexts_projects',
    'local_contexts_projects'
  ]
  @@resolved_attributes += @local_contexts_resolves
  AppConfig[:record_inheritance_resolves] += @local_contexts_resolves

  add_indexer_initialize_hook do |indexer|
    if AppConfig[:plugins].include?('local_contexts_projects')
      indexer.add_document_prepare_hook {|doc, record|
        record_data = record['record']
        doc['local_contexts_project_uris_u_sstr'] = []
        doc['local_contexts_project_u_sbool'] = nil
        if ['accession', 'resource', 'archival_object', 'digital_object', 'digital_object_component'].include?(doc['primary_type']) && record['record']['local_contexts_projects']
          unless record['record']['local_contexts_projects'].empty?
            doc['local_contexts_project_u_sbool'] = true
            record_data['local_contexts_projects'].each do |lcp|
              doc['local_contexts_project_uris_u_sstr'] << lcp['ref']
            end
          end
        end

        if ['archival_object', 'digital_object_component'].include?(doc['primary_type'])
          doc['inherited_local_contexts_projects_u_sstr'] = []
          # only check if the object is not already tagged
          if doc['local_contexts_project_uris_u_sstr'].empty?
            if record_data['ancestors'].nil?
              record_data = resolve_ancestors_for_pui(record)
            end

            get_local_contexts_data(record_data, doc)
          end
        end
      }
    end
  end

  self.add_indexer_initialize_hook do |indexer|
    indexer.add_document_prepare_hook {|doc, record|
      if doc['primary_type'] == 'local_contexts_project'
        record_data = record['record']
        doc['json'] = record_data.to_json
        doc['title'] = record_data['display_string']
        doc['display_string'] = record_data['display_string']
        doc['local_contexts_project_typeahead_sort_key_u_sort'] = record_data['display_string']
      end
    }
  end

  def self.resolve_ancestors_for_pui(record)
    JSONModel::HTTP.get_json(record['uri'], 'resolve[]' => @local_contexts_resolves)
  end

  def self.get_local_contexts_data(record, doc)
    inherited_lcps = []
    inherit_level = nil
    inherit_uri = nil
    if record['ancestors'] && record['ancestors'].length > 0
      record['ancestors'].each do |anc|
        anc_data = anc['_resolved']
        next if anc_data['local_contexts_projects'].nil?
        break if inherited_lcps.length > 0
        inherit_uri = anc_data['uri']
        if anc_data['jsonmodel_type'] == 'digital_object'
          inherit_level = 'digital object'
        elsif anc_data['jsonmodel_type'] == 'digital_object_component'
          inherit_level = 'digital object component'
        else 
          inherit_level = anc_data['level']
        end
        anc_data['local_contexts_projects'].each do |lcp|
          inherited_lcps << lcp['_resolved']
        end
      end
      if inherited_lcps.length > 0
        doc['inherited_local_contexts_projects_u_sstr'] << {'local_contexts_projects' => inherited_lcps, 'level' => inherit_level, 'parent_uri' =>inherit_uri}.to_json
      end
    end
  end

end
