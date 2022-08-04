Plugins::extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))

Rails.application.config.after_initialize do

  unless AppConfig.has_key?(:local_contexts_base_url)
    AppConfig[:local_contexts_base_url] = "https://localcontextshub.org"
    AppConfig[:local_contexts_open_to_collab_url] = AppConfig[:local_contexts_base_url] + 'notice'
  end

  # only add faceting if configured
  if AppConfig.has_key?(:local_contexts_projects) && AppConfig[:local_contexts_projects]['public_faceting'] == true
    Searchable.module_eval do
      alias_method :pre_local_contexts_project_set_up_advanced_search, :set_up_advanced_search
      def set_up_advanced_search(default_types = [],default_facets=[],default_search_opts={}, params={})
        default_facets << 'local_contexts_project_u_sbool'
        pre_local_contexts_project_set_up_advanced_search(default_types, default_facets, default_search_opts, params)
      end
    end
  end

  class ArchivesSpaceClient
    def get_data_from_local_contexts_api(id, type, use_cache)
      uri = "/local_contexts_projects/get_local_contexts_api_data"
      params = {:id => id, :type => type, :use_cache => use_cache}
      url = build_url(uri, params)
      if id && type
        request = Net::HTTP::Get.new(url)
        response = do_http_request(request)
        if response.code != '200'
          Rails.logger.debug("Code: #{response.code}")
          raise RequestFailedException.new("#{response.code}: #{response.body}")
        end
        results = ASUtils.json_parse(response.body)
        results
      end
    end
  end

end
