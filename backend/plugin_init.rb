require 'fileutils'
require 'aspace_logger'
require_relative 'lib/local_contexts_ead'
require_relative 'lib/ead_exporter_overrides'
require_relative 'lib/ead3_exporter_overrides'

unless AppConfig.has_key?(:local_contexts_base_url)
  AppConfig[:local_contexts_base_url] = "https://localcontextshub.org/"
end

unless AppConfig.has_key?(:local_contexts_replace_xsl)
  AppConfig[:local_contexts_replace_xsl] = true
end

unless AppConfig.has_key?(:local_contexts_open_to_collaborate_cache_time)
  AppConfig[:local_contexts_open_to_collaborate_cache_time] = 2592000 # 30 days
end

unless AppConfig.has_key?(:local_contexts_cache_time)
  AppConfig[:local_contexts_cache_time] = 604800 # 7 days
end

unless AppConfig.has_key?(:local_contexts_api_path) 
  AppConfig[:local_contexts_api_path] = "api/v1"
end

unless AppConfig.has_key?(:local_contexts_refresh_cache_cron)
  AppConfig[:local_contexts_refresh_cache_period] = "0 1 * * 0" # every sunday at 1 am
end

# define the wait till we hit the api again for full (all projects) cache reset
unless AppConfig.has_key?(:local_contexts_api_wait_time)
  AppConfig[:local_contexts_api_wait_time] = 30 # 30 seconds recommended by Local Contexts
end

Permission.define("manage_localcontexts_records",
                  "The ability to create/update/delete Local Contexts Project records",
                  :level => "repository")

Permission.define("update_localcontexts_project_record",
                  "The ability to create/update/delete Local Contexts Project records",
                  :implied_by => 'manage_localcontexts_records',
                  :level => "global")


# create the pui sitemaps directory if it does not already exist
ArchivesSpaceService.loaded_hook do

  logger = Logger.new($stderr)

  AppConfig[:local_contexts_cache_dirname] = File.join(AppConfig[:data_directory], "local_contexts_cache")
  unless File.directory?(AppConfig[:local_contexts_cache_dirname])
    FileUtils.mkdir_p(AppConfig[:local_contexts_cache_dirname])
  end 
  
  unless AppConfig[:local_contexts_replace_xsl] == false

    lc_xsl_orig_filename = "as-ead-pdf-lc-moved-orig.xsl"
    as_ead_pdf_filename = "as-ead-pdf.xsl"

    if File.file?(File.join(ASUtils.find_base_directory, 'stylesheets', lc_xsl_orig_filename))
      logger.info("Local Contexts EAD to PDF stylesheet has already been moved to main stylesheet directory")
    else
      logger.info("Copying Local Contexts EAD to PDF stylesheet to main stylesheet directory. Old stylesheet has been renamed #{lc_xsl_orig_filename}.")
      pdf_xsl_file = File.join(ASUtils.find_base_directory, 'stylesheets', as_ead_pdf_filename)
      lc_pdf_xsl_file = File.join(ASUtils.find_local_directories(nil, 'local_contexts_projects').shift, 'stylesheets', as_ead_pdf_filename)
      FileUtils.mv(pdf_xsl_file, File.join(ASUtils.find_base_directory, 'stylesheets', lc_xsl_orig_filename))
      FileUtils.cp(lc_pdf_xsl_file, File.join(ASUtils.find_base_directory, 'stylesheets', as_ead_pdf_filename))
    end
  end
  
end

ArchivesSpaceService.settings.scheduler.cron(AppConfig[:local_contexts_refresh_cache_cron], :allow_overlapping => false) do
  LocalContextsClient.new.check_cache
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
