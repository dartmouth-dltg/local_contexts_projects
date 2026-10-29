class IndexerCommon

  @@record_types << :local_contexts_project
  @@global_types << :local_contexts_project

  LOCAL_CONTEXTS_TYPES = ['accession', 'resource', 'archival_object', 'digital_object', 'digital_object_component'].freeze
  LOCAL_CONTEXTS_CHILD_TYPES = ['archival_object', 'digital_object_component'].freeze

  # The PUI shows resolved projects, inherited projects and projects on linked
  # digital objects. The PUI indexer only builds documents for record inheritance
  # types (by default just archival objects); for every other type (resources,
  # accessions, digital objects, components) the PUI shows the staff indexer's
  # document. So both indexers need these resolved, in the batch fetch rather than
  # with a GET per record.
  LOCAL_CONTEXTS_RESOLVES = [
    'ancestors',
    'ancestors::local_contexts_projects',
    'instances::digital_object::local_contexts_projects',
    'local_contexts_projects'
  ].freeze
  LOCAL_CONTEXTS_RESOLVES.each {|attr| add_attribute_to_resolve(attr)}

  # Inherited projects are only needed in the document the PUI shows for a type
  def self.local_contexts_pui_document?(indexer, type)
    pui = defined?(PUIIndexer) && indexer.is_a?(PUIIndexer)
    inheritance_type = defined?(RecordInheritance) && RecordInheritance.has_type?(type)
    inheritance_type ? pui : !pui
  end

  # Core builds each staff document's json from the whole record, so with
  # ancestors resolved every archival object and component would store a full
  # copy of each ancestor. The hooks read ancestors from the record, so drop the
  # resolved copies from the json once they have all run. Other plugins that do
  # the same check the shared flag, so the json is only rewritten once. (The PUI
  # indexer removes ancestors from its own documents.)
  def self.strip_resolved_ancestors_from_json(doc, record)
    return if record['resolved_ancestors_stripped'] || doc['json'].nil?
    return unless Array(record['record']['ancestors']).any? {|anc| anc.is_a?(Hash) && anc['_resolved'] }

    json = ASUtils.json_parse(doc['json'])
    Array(json['ancestors']).each {|anc| anc.delete('_resolved') if anc.is_a?(Hash) }
    doc['json'] = ASUtils.to_json(json)
    record['resolved_ancestors_stripped'] = true
  end

  # final_doc_rules (archivesspace #3667) runs after all plugin hooks. Only add it
  # where core has it: the hook ordering below checks for it to detect older releases
  LOCAL_CONTEXTS_CORE_FINAL_DOC_RULES = Object.private_method_defined?(:final_doc_rules) || method_defined?(:final_doc_rules)

  if LOCAL_CONTEXTS_CORE_FINAL_DOC_RULES
    module LocalContextsStripResolvedAncestors
      def final_doc_rules
        super
        unless defined?(PUIIndexer) && is_a?(PUIIndexer)
          add_document_prepare_hook {|doc, record| IndexerCommon.strip_resolved_ancestors_from_json(doc, record) }
        end
      end
    end
    prepend LocalContextsStripResolvedAncestors
  end

  add_indexer_initialize_hook do |indexer|
    if AppConfig[:plugins].include?('local_contexts_projects')
      # child types whose PUI document this indexer builds
      inherited_types = LOCAL_CONTEXTS_CHILD_TYPES.select {|type| local_contexts_pui_document?(indexer, type) }

      hook = proc {|doc, record|
        doc['local_contexts_project_uris_u_sstr'] = []
        doc['local_contexts_project_u_sbool'] = nil
        next unless LOCAL_CONTEXTS_TYPES.include?(doc['primary_type'])

        lcps = Array(record['record']['local_contexts_projects'])
        unless lcps.empty?
          doc['local_contexts_project_u_sbool'] = true
          doc['local_contexts_project_uris_u_sstr'].concat(lcps.map {|lcp| lcp['ref']})
        end

        next unless inherited_types.include?(doc['primary_type'])

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

      # older releases: strip after this plugin's hooks instead (see above)
      unless LOCAL_CONTEXTS_CORE_FINAL_DOC_RULES || (defined?(PUIIndexer) && indexer.is_a?(PUIIndexer))
        indexer.add_document_prepare_hook {|doc, record| IndexerCommon.strip_resolved_ancestors_from_json(doc, record) }
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
      record_data = JSONModel::HTTP.get_json(record['uri'], 'resolve[]' => LOCAL_CONTEXTS_RESOLVES)
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
