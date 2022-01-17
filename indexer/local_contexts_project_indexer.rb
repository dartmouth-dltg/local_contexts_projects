class IndexerCommon

  @@record_types << :local_contexts_project
  @@global_types << :local_contexts_project
  @@resolved_attributes << :local_contexts_projects

  add_indexer_initialize_hook do |indexer|
    if AppConfig[:plugins].include?('local_contexts_project')
      indexer.add_document_prepare_hook {|doc, record|
        if ['accession','resource', 'archival_object', 'digital_object'].include?(doc['primary_type']) && record['record']['local_contexts_project']
          doc['local_contexts_project_u_sbool'] = true
        else
          doc['local_contexts_project_u_sbool'] = false
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
