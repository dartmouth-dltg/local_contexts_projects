Rails.application.config.after_initialize do

  # only add faceting if configured
  if AppConfig.has_key?(:aspace_local_contexts) && AppConfig[:aspace_local_contexts]['public_faceting'] == true
    Searchable.module_eval do
      alias_method :pre_local_contexts_set_up_advanced_search, :set_up_advanced_search
      def set_up_advanced_search(default_types = [],default_facets=[],default_search_opts={}, params={})
        default_facets << 'local_contexts_u_sbool'
        pre_local_contexts_set_up_advanced_search(default_types, default_facets, default_search_opts, params)
      end
    end
  end

end
