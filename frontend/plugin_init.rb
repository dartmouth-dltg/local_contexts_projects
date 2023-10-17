ArchivesSpace::Application.extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))

Rails.application.config.after_initialize do

  unless AppConfig.has_key?(:local_contexts_base_url)
    AppConfig[:local_contexts_base_url] = "https://localcontextshub.org"
  end

  # only add faceting if configured
  if AppConfig.has_key?(:local_contexts_projects) && AppConfig[:local_contexts_projects]['staff_faceting'] == true
    SearchResultData.class_eval do
      self.singleton_class.send(:alias_method, :BASE_FACETS_pre_local_contexts_project, :BASE_FACETS)
      def self.BASE_FACETS
        self.BASE_FACETS_pre_local_contexts_project << "local_contexts_project_u_sbool"
      end
    end
  end

  # one can choose to remove the Local Contexxts Projects from the facets in search
  if AppConfig.has_key?(:local_contexts_projects) && AppConfig[:local_contexts_projects]['local_contexts_project_faceting'] == false
    class SearchResultData
      alias_method :facets_for_filter_pre_local_contexts_project, :facets_for_filter
      def facets_for_filter
        facet_data_for_filter = facets_for_filter_pre_local_contexts_project
        # plugin modification
        # delete the TK facet
        facet_data_for_filter.each {|facet_group, facets|
          facets.delete_if {|facet, facet_map|
            facet == 'local_contexts_project'
          }
        }
        # end modification

        facet_data_for_filter
      end
    end
  end

  ActionView::PartialRenderer.class_eval do
    alias_method :render_pre_local_contexts_project, :render
    def render(context, options, block)
      result = render_pre_local_contexts_project(context, options, block);

      # Add our local contexts project specific templates to shared/templates
      if options[:partial] == "shared/templates"
        result += render(context, options.merge(:partial => "local_contexts_projects/render_templates"), nil)
      end

      result
    end
  end

  ApplicationController.class_eval do

    alias_method :find_opts_pre_local_contexts_project, :find_opts
    alias_method :browse_columns_pre_local_contexts_project, :browse_columns

    def find_opts
      orig = find_opts_pre_local_contexts_project
      orig.merge('resolve[]' => orig['resolve[]'] + ['local_contexts_projects'])
    end

     def browse_columns
       browse_columns = browse_columns_pre_local_contexts_project
       browse_columns["local_contexts_project_browse_column_1"] = "title"
       browse_columns["local_contexts_project_sort_column"] = "title"
       browse_columns["local_contexts_project_sort_direction"] = "asc"
       @browse_columns = browse_columns
     end

  end

  PreferencesController.class_eval do

    alias_method :edit_pre_local_contexts, :edit

    def edit
      SearchAndBrowseColumnConfig.columns.delete('local_contexts_project')
      edit_pre_local_contexts
    end
  end

  SearchHelper.class_eval do

    alias_method :can_edit_search_result_pre_local_contexts_project?, :can_edit_search_result?
    alias_method :column_opts_pre_local_contexts_project, :column_opts

    def can_edit_search_result?(record)
      return user_can?('update_localcontexts_project_record', record['id']) if record['primary_type'] === "local_contexts_project"
      can_edit_search_result_pre_local_contexts_project?(record)
    end

    def column_opts
      column_opts = column_opts_pre_local_contexts_project
      column_opts['local_contexts_project'] = {
          "title" => {
            :field => "display_string",
            :sortable => true,
            :sort_by => "title_sort"},
          "audit_info": {
            :field => "audit_info",
            :sort_by => [
                "create_time",
                "user_mtime"
            ]}
          }
      @@column_opts = column_opts
    end

  end

  JSONModel(:local_contexts_project)

end
