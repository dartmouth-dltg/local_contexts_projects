class LocalContextsEADHelper

  DEFAULT_EAD_TAG = 'odd'

  # The Open to Collaborate response nests the notice under 'notice'; accept a
  # flat notice too.
  def self.otc_notice(otc)
    return {} unless otc.is_a?(Hash)

    notice = otc['notice']
    notice = notice.first if notice.is_a?(Array)
    notice.is_a?(Hash) ? notice : otc
  end

  # A label's community is a name in some API versions and an object with a
  # 'name' in others.
  def self.community_name(item)
    community = item['community']
    community = community['name'] if community.is_a?(Hash)
    community.to_s.empty? ? nil : community.to_s
  end

  # Only well formed translations
  def self.translations(item)
    Array(item['translations']).select {|translation| translation.is_a?(Hash) }
  end

  # EAD/EAD3 tag for a label or notice type; group is 'notices', 'tk_labels' or 'bc_labels'.
  # Types missing from the map fall back to a generic tag instead of failing the export.
  def self.ead_tag_for(group, type)
    tag = AppConfig[:local_contexts_label_ead_tag_map].dig(group, type)
    return tag if tag

    Log.info("Label or notice type: #{type} not found in AppConfig[:local_contexts_label_ead_tag_map]['#{group}']. Please add a mapping to an EAD/EAD3 tag. Using <#{DEFAULT_EAD_TAG}>.")
    DEFAULT_EAD_TAG
  end

  def self.include_lcps?(lcps)
    lcps_to_use = []

    return lcps_to_use if lcps.nil?
    
    lcps.each do |lcp|
      unless lcp['_resolved']
        id = JSONModel.parse_reference(lcp['ref'])[:id]
        lc_obj = LocalContextsProject.get_or_die(id)
        resolved = URIResolver.resolve_references(LocalContextsProject.to_jsonmodel(lc_obj), [])
        lcp['_resolved'] = resolved.to_hash
      end
      if lcp['_resolved']['project_is_public'] === true
        lcps_to_use << lcp
      end
    end
    lcps_to_use
  end
  
end
