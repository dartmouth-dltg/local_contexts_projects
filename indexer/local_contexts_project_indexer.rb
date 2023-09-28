class IndexerCommon

  @@record_types << :local_contexts_project
  @@global_types << :local_contexts_project
  @@resolved_attributes << :local_contexts_projects
  @@resolved_attributes << 'instances::digital_object::_resolved::local_contexts_projects'

  add_indexer_initialize_hook do |indexer|
    if AppConfig[:plugins].include?('local_contexts_projects')
      indexer.add_document_prepare_hook {|doc, record|
        doc['local_contexts_project_uris_u_sstr'] = []
        doc['local_contexts_project_u_sbool'] = nil
        if ['accession', 'resource', 'archival_object', 'digital_object', 'digital_object_component'].include?(doc['primary_type']) && record['record']['local_contexts_projects']
          unless record['record']['local_contexts_projects'].empty?
            doc['local_contexts_project_u_sbool'] = true
            record['record']['local_contexts_projects'].each do |lcp|
              doc['local_contexts_project_uris_u_sstr'] << lcp['ref']
            end
          end
        end

        if ['archival_object', 'digital_object_component'].include?(doc['primary_type'])
          doc['inherited_local_contexts_projects_u_sstr'] = []
          # only check if the object is not already tagged
          if doc['local_contexts_project_uris_u_sstr'].empty?
            if record['record']['parent']
              get_parent_local_context_uris(record['record']['parent']['ref'], doc)
            elsif record['record']['resource']
              get_parent_local_context_uris(record['record']['resource']['ref'], doc)
            elsif record['record']['digital_object']
              get_parent_local_context_uris(record['record']['digital_object']['ref'], doc)
            end
          end
        end
      }
    end
  end

  self.add_indexer_initialize_hook do |indexer|
    indexer.add_document_prepare_hook {|doc, record|
      if doc['primary_type'] == 'local_contexts_project'
        doc['json'] = record['record'].to_json
        doc['title'] = record['record']['display_string']
        doc['display_string'] = record['record']['display_string']

        doc['local_contexts_project_typeahead_sort_key_u_sort'] = record['record']['display_string']
      end
    }
  end

  def self.get_parent_local_context_uris(uri, doc)
    inherited_lcps = []
    parent = JSONModel::HTTP.get_json(uri, "resolve[]" => "local_contexts_projects")
    parent['local_contexts_projects'].each do |lcp|
      inherited_lcps << lcp['_resolved']
    end
    if inherited_lcps.length > 0
      if parent['jsonmodel_type'] == 'digital_object'
        parent['level'] = 'digital object'
      elsif parent['jsonmodel_type'] == 'digital_object_component'
        parent['level'] = 'digital object component'
      end
      doc['inherited_local_contexts_projects_u_sstr'] << {'local_contexts_projects' => inherited_lcps, 'level' => parent['level'], 'parent_uri' => parent['uri']}.to_json
    end
    if doc['inherited_local_contexts_projects_u_sstr'].empty?
      if parent['parent']
        get_parent_local_context_uris(parent['parent']['ref'], doc)
      elsif parent['resource']
        get_parent_local_context_uris(parent['resource']['ref'], doc)
      elsif parent['digital_object']
        get_parent_local_context_uris(parent['record']['digital_object']['ref'], doc)
      end
    end
  end

end
