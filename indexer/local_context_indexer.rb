class IndexerCommon

  add_indexer_initialize_hook do |indexer|
    if AppConfig[:plugins].include?('local_context')
      indexer.add_document_prepare_hook {|doc, record|
        if ['accession','resource', 'archival_object', 'digital_object'].include?(doc['primary_type']) && record['record']['local_context']
          doc['local_context_u_sbool'] = true
        else
          doc['local_context_u_sbool'] = false
        end
      }
    end
  end

end
