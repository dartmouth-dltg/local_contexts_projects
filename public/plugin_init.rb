my_routes = File.join(File.dirname(__FILE__), "routes.rb")
Plugins.extend_aspace_routes(my_routes)

Rails.application.config.after_initialize do

  # only add faceting if configured
  if AppConfig.has_key?(:local_context) && AppConfig[:local_context]['public_faceting'] == true
    Searchable.module_eval do
      alias_method :pre_local_contexts_set_up_advanced_search, :set_up_advanced_search
      def set_up_advanced_search(default_types = [],default_facets=[],default_search_opts={}, params={})
        default_facets << 'local_contexts_u_sbool'
        pre_local_contexts_set_up_advanced_search(default_types, default_facets, default_search_opts, params)
      end
    end
  end

end
