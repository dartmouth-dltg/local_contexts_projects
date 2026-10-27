class IndexerCommon

  @@record_types << :local_contexts_project
  @@global_types << :local_contexts_project

  LOCAL_CONTEXTS_TYPES = ['accession', 'resource', 'archival_object', 'digital_object', 'digital_object_component'].freeze
  LOCAL_CONTEXTS_CHILD_TYPES = ['archival_object', 'digital_object_component'].freeze

  # Only the PUI reads resolved Local Contexts data from the index: the projects
  # on a record, projects inherited from an ancestor, and projects on linked
  # digital objects. The staff index only needs the project refs, which come
  # unresolved. add_attribute_to_resolve applies to every indexer, so it made the
  # staff indexer fetch the full JSON of every ancestor of every archival object.
  # Add these to the PUI's own resolves instead (it already resolves 'ancestors'
  # for record inheritance), so the batch fetch covers them without a GET per record.
  LOCAL_CONTEXTS_PUI_RESOLVES = [
    'ancestors',
    'ancestors::local_contexts_projects',
    'instances::digital_object::local_contexts_projects',
    'local_contexts_projects'
  ].freeze

  # PUIIndexer reads this when it loads, which is after the plugin indexers
  AppConfig[:record_inheritance_resolves] = (Array(AppConfig[:record_inheritance_resolves]) + LOCAL_CONTEXTS_PUI_RESOLVES).uniq

  add_indexer_initialize_hook do |indexer|
    if AppConfig[:plugins].include?('local_contexts_projects')
      # only the PUI shows inherited projects, and only it resolves ancestors
      pui = defined?(PUIIndexer) && indexer.is_a?(PUIIndexer)

      hook = proc {|doc, record|
        doc['local_contexts_project_uris_u_sstr'] = []
        doc['local_contexts_project_u_sbool'] = nil
        next unless LOCAL_CONTEXTS_TYPES.include?(doc['primary_type'])

        lcps = Array(record['record']['local_contexts_projects'])
        unless lcps.empty?
          doc['local_contexts_project_u_sbool'] = true
          doc['local_contexts_project_uris_u_sstr'].concat(lcps.map {|lcp| lcp['ref']})
        end

        next unless pui && LOCAL_CONTEXTS_CHILD_TYPES.include?(doc['primary_type'])

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
      record_data = JSONModel::HTTP.get_json(record['uri'], 'resolve[]' => LOCAL_CONTEXTS_PUI_RESOLVES)
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
      # every untagged descendant stores a copy, so keep only what the PUI reads
      'local_contexts_projects' => anc['local_contexts_projects'].map {|lcp| lcp['_resolved'] }.compact.map {|project|
        project.slice('project_id', 'project_is_public')
      },
      'level' => level,
      'parent_uri' => anc['uri']
    }.to_json
  end

end
