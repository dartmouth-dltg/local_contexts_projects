class LocalContextsEADHelper

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
