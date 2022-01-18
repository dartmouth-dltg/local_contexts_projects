Plugins::extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))

Rails.application.config.after_initialize do

  unless AppConfig.has_key?(:local_contexts_base_url)
    AppConfig[:local_contexts_base_url] = "https://localcontextshub.org"
  end

  # only add faceting if configured
  if AppConfig.has_key?(:local_contexts_project) && AppConfig[:local_contexts_project]['public_faceting'] == true
    Searchable.module_eval do
      alias_method :pre_local_contexts_project_set_up_advanced_search, :set_up_advanced_search
      def set_up_advanced_search(default_types = [],default_facets=[],default_search_opts={}, params={})
        default_facets << 'local_contexts_project_u_sbool'
        pre_local_contexts_project_set_up_advanced_search(default_types, default_facets, default_search_opts, params)
      end
    end
  end

  class ArchivesSpaceClient
    def get_data_from_api(id, type)
      uri = "/local_contexts_projects/get_local_contexts_api_data"
      params = {:id => id, :type => type}
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
