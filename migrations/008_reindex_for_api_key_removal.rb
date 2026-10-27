require 'db/migrations/utils'

# Project API keys used to be indexed (in display_string and in the resolved
# project attached to linked records). They are now masked by the backend, so
# the records that carried a key in their indexed documents must be reindexed.
#
# The indexers pick up records by system_mtime, so bump it on:
#  - the projects themselves
#  - records linked to a project
#  - the whole tree of any linked resource, archival object, digital object or
#    digital object component (descendants index their ancestors' projects)
#  - records with an instance linked to a digital object that has a project
#    (just those records: their descendants don't inherit instances)
Sequel.migration do

  up do
    $stderr.puts("Marking records with Local Contexts projects for reindex to remove API keys from the index")

    now = Time.now
    touch = lambda do |table, column, ids|
      ids.compact.uniq.each_slice(1000) do |slice|
        self[table].where(column => slice).update(:system_mtime => now)
      end
    end

    links = self[:local_contexts_project_rlshp]
    linked = lambda {|column| links.exclude(column => nil).select_map(column) }

    resource_ids = linked.call(:resource_id)
    accession_ids = linked.call(:accession_id)
    digital_object_ids = linked.call(:digital_object_id)

    # records whose instances link a digital object that has a project
    instance_ids = self[:instance_do_link_rlshp].where(:digital_object_id => digital_object_ids).select_map(:instance_id)
    instances = instance_ids.each_slice(1000).flat_map {|slice| self[:instance].where(:id => slice).select_map([:resource_id, :archival_object_id, :accession_id]) }
    instance_resource_ids = instances.map {|row| row[0] }
    instance_ao_ids = instances.map {|row| row[1] }
    instance_accession_ids = instances.map {|row| row[2] }

    # trees: roots of the linked archival objects and digital object components
    ao_ids = linked.call(:archival_object_id)
    doc_ids = linked.call(:digital_object_component_id)
    ao_roots = ao_ids.uniq.each_slice(1000).flat_map {|slice| self[:archival_object].where(:id => slice).select_map(:root_record_id) }
    doc_roots = doc_ids.uniq.each_slice(1000).flat_map {|slice| self[:digital_object_component].where(:id => slice).select_map(:root_record_id) }

    resource_roots = (resource_ids + ao_roots).compact.uniq
    digital_object_roots = (digital_object_ids + doc_roots).compact.uniq

    touch.call(:local_contexts_project, :id, self[:local_contexts_project].select_map(:id))
    touch.call(:resource, :id, resource_roots)
    touch.call(:archival_object, :root_record_id, resource_roots)
    touch.call(:resource, :id, instance_resource_ids)
    touch.call(:archival_object, :id, instance_ao_ids)
    touch.call(:accession, :id, accession_ids + instance_accession_ids)
    touch.call(:digital_object, :id, digital_object_roots)
    touch.call(:digital_object_component, :root_record_id, digital_object_roots)
  end

end
