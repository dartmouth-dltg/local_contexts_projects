class IndexerCommon

  @@record_types << :local_contexts_project
  @@global_types << :local_contexts_project

  LOCAL_CONTEXTS_TYPES = ['accession', 'resource', 'archival_object', 'digital_object', 'digital_object_component'].freeze
  LOCAL_CONTEXTS_CHILD_TYPES = ['archival_object', 'digital_object_component'].freeze

  # resolve ancestors in the batch fetch so we don't need a GET per record
  @local_contexts_resolves = [
    'ancestors',
    'ancestors::local_contexts_projects',
    'instances::digital_object::local_contexts_projects',
    'local_contexts_projects'
  ]
  @local_contexts_resolves.each {|attr| add_attribute_to_resolve(attr)}

  add_indexer_initialize_hook do |indexer|
    if AppConfig[:plugins].include?('local_contexts_projects')
      hook = proc {|doc, record|
        doc['local_contexts_project_uris_u_sstr'] = []
        doc['local_contexts_project_u_sbool'] = nil
        next unless LOCAL_CONTEXTS_TYPES.include?(doc['primary_type'])

        lcps = Array(record['record']['local_contexts_projects'])
        unless lcps.empty?
          doc['local_contexts_project_u_sbool'] = true
          doc['local_contexts_project_uris_u_sstr'].concat(lcps.map {|lcp| lcp['ref']})
        end

        next unless LOCAL_CONTEXTS_CHILD_TYPES.include?(doc['primary_type'])

        doc['inherited_local_contexts_projects_u_sstr'] = []
        # only check if the object is not already tagged
        next unless lcps.empty?

        ancestors = local_contexts_resolved_ancestors(record)
        ancestor = ancestors.find {|anc| anc['_resolved'] && !Array(anc['_resolved']['local_contexts_projects']).empty?}
        doc['inherited_local_contexts_projects_u_sstr'] << local_contexts_inherited_data(ancestor['_resolved']) if ancestor
      }

      # PUIIndexer's own prepare hook deletes record['record']['ancestors']. Before
      # final_doc_rules (archivesspace #3667) it ran ahead of plugin hooks, so go
      # first there or every AO costs a backend GET
      if indexer.respond_to?(:final_doc_rules, true)
        indexer.add_document_prepare_hook(&hook)
      else
        indexer.instance_variable_get(:@document_prepare_hooks).unshift(hook)
      end
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

  # fall back to fetching the record if ancestors somehow arrived unresolved
  def self.local_contexts_resolved_ancestors(record)
    ancestors = record['record']['ancestors']
    if ancestors.nil? || ancestors.any? {|anc| anc['_resolved'].nil?}
      record_data = JSONModel::HTTP.get_json(record['uri'], 'resolve[]' => @local_contexts_resolves)
      ancestors = record_data && record_data['ancestors']
    end
    Array(ancestors)
  end

  def self.local_contexts_inherited_data(anc)
    level = case anc['jsonmodel_type']
            when 'digital_object' then 'digital object'
            when 'digital_object_component' then 'digital object component'
            else anc['level']
            end

    {
      'local_contexts_projects' => anc['local_contexts_projects'].map {|lcp| lcp['_resolved']},
      'level' => level,
      'parent_uri' => anc['uri']
    }.to_json
  end

end
