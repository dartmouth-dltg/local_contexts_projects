require 'fileutils'
require_relative 'lib/local_contexts_ead'

unless AppConfig.has_key?(:local_contexts_base_url)
  AppConfig[:local_contexts_base_url] = "https://localcontextshub.org/"
end

unless AppConfig.has_key?(:local_contexts_replace_xsl)
  AppConfig[:local_contexts_replace_xsl] = true
end

AppConfig[:local_contexts_api_path] = "api/v1"

Permission.define("manage_local_contexts_project_record",
                  "The ability to create/update/delete Local Contexts Project records",
                  :level => "global")

# create the pui sitemaps directory if it does not already exist
ArchivesSpaceService.loaded_hook do
  cache_dirname = File.join(AppConfig[:data_directory], "local_contexts_cache")
  unless File.directory?(cache_dirname)
    FileUtils.mkdir_p(cache_dirname)
  end 
  
  pdf_xsl_file = File.join(ASUtils.find_base_directory, 'stylesheets', 'as-ead-pdf.xsl')
  lc_pdf_xsl_file = File.join(ASUtils.find_local_directories(nil, 'local_contexts_project').shift, 'stylesheets', 'as-ead-pdf.xsl')
  unless AppConfig[:local_contexts_replace_xsl] == false
    FileUtils.mv(pdf_xsl_file, File.join(ASUtils.find_base_directory, 'stylesheets', 'as-ead-pdf-orig.xsl'))
    FileUtils.cp(lc_pdf_xsl_file, File.join(ASUtils.find_base_directory, 'stylesheets', 'as-ead-pdf.xsl'))
  end 
  
end

Solr.add_search_hook do |query|

  # If we're doing a typeahead, replace our search fields to only match display
  # strings.
  query.instance_eval do
    if Hash[@solr_params][:sort] =~ /local_contexts_project_typeahead_sort_key_u_sort/
      @solr_params = @solr_params.reject {|k, v| k == :qf}
      @solr_params << [:qf, "display_string"]
    end
  end

  query

end
