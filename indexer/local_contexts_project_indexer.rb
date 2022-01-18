class IndexerCommon

  @@record_types << :local_contexts_project
  @@global_types << :local_contexts_project
  @@resolved_attributes << :local_contexts_projects

  add_indexer_initialize_hook do |indexer|
    if AppConfig[:plugins].include?('local_contexts_project')
      indexer.add_document_prepare_hook {|doc, record|
        doc['local_contexts_project_uris_u_sstr'] = []
        if ['accession','resource', 'archival_object', 'digital_object', 'digital_object_component'].include?(doc['primary_type']) && record['record']['local_contexts_projects']
          if record['record']['local_contexts_projects'].length > 0
            doc['local_contexts_project_u_sbool'] = true
          else
            doc['local_contexts_project_u_sbool'] = false
          end
          record['record']['local_contexts_projects'].each do |lcp|
            doc['local_contexts_project_uris_u_sstr'] << lcp['ref']
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


end
