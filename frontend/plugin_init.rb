ArchivesSpace::Application.extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))

Rails.application.config.after_initialize do

  unless AppConfig.has_key?(:local_context_base_url)
    AppConfig[:local_context_base_url] = "https://localcontextshub.org"
  end

  # only add faceting if configured
  if AppConfig.has_key?(:local_context) && AppConfig[:local_context]['staff_faceting'] == true
    SearchResultData.class_eval do
      self.singleton_class.send(:alias_method, :BASE_FACETS_pre_local_contexts, :BASE_FACETS)
      def self.BASE_FACETS
        self.BASE_FACETS_pre_local_contexts << "local_contexts_u_sbool"
      end
    end
  end

  ActionView::PartialRenderer.class_eval do
    alias_method :render_pre_local_context, :render
    def render(context, options, block)
      result = render_pre_local_context(context, options, block);

      # Add our cart-specific templates to shared/templates
      if options[:partial] == "shared/templates"
        result += render(context, options.merge(:partial => "local_context/render_templates"), nil)
      end

      result
    end
  end

end
