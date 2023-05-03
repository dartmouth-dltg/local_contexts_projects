require 'fileutils'
require 'thread'
require 'aspace_logger'
require_relative 'lib/local_contexts_ead_helper'
require_relative 'lib/local_contexts_ead'
require_relative 'lib/local_contexts_ead3'
require_relative 'lib/local_contexts_serializer'
require_relative 'lib/ead_exporter_overrides'
require_relative 'lib/ead3_exporter_overrides'
require_relative 'lib/aspace_patches'
require_relative 'lib/local_contexts_marc_serialize'

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
  AppConfig[:local_contexts_refresh_cache_cron] = "0 1 * * 0" # every sunday at 1 am
end

# define the wait till we hit the api again for full (all projects) cache reset
unless AppConfig.has_key?(:local_contexts_api_wait_time)
  AppConfig[:local_contexts_api_wait_time] = 30 # 30 seconds recommended by Local Contexts
end

AppConfig[:local_contexts_label_ead_tag_map] = {
  # Notices
  'notices' => {
    'traditional_knowledge' => 'userestrict',
    'biocultural' => 'userestrict',
    'attribution_incomplete' => 'custodhist',
    'open_to_collaborate' => 'odd',
  },

  # TK Labels
  'tk_labels' => {
    'attribution' => 'custodhist',
    'clan' => 'custodhist',
    'family' => 'custodhist',
    'outreach' => 'userestrict',
    'tk_multiple_community' => 'custodhist',
    'non_verified' => 'accessrestrict',
    'verified' => 'accessrestrict',
    'non_commercial' => 'userestrict',
    'commercial' => 'userestrict',
    'culturally_sensitive' => 'accessrestrict',
    'community_voice' => 'custodhist',
    'community_use_only' => 'userestrict',
    'seasonal' => 'accessrestrict',
    'women_general' => 'accessrestrict',
    'men_general' => 'accessrestrict',
    'men_restricted' => 'accessrestrict',
    'women_restricted' => 'accessrestrict',
    'secret_sacred' => 'accessrestrict',
    'open_to_collaboration' => 'userestrict',
    'creative' => 'custodhist',
  },

  # BC Labels
  'bc_labels' => {
    'provenance' => 'custodhist',
    'commercialization' => 'userestrict',
    'non_commercial' => 'userestrict',
    'collaboration' => 'userestrict',
    'consent_verified' => 'accessrestrict',
    'consent_non_verified' => 'accessrestrict',
    'multiple_community' => 'custodhist',
    'research' => 'userestrict',
    'clan' => 'custodhist',
    'outreach' => 'userestrict'
  }
}

# FIXME: Incomplete & needs further review
# May also require additional logic in MARC serializer if contents 
# need to be split across multiple subfields
# or if multiple indicators are necessary
AppConfig[:local_contexts_label_marc_tag_map] = {
  # Notices
  'notices' => {
    'traditional_knowledge' => {'tag_number' => '540', "indicator" => '', 'subfield' => 'a'},
    'biocultural' => {'tag_number' => '540', 'subfield' => 'a'},
    'attribution_incomplete' => {'tag_number' => '561', 'subfield' => ''},
    'open_to_collaborate' => {'tag_number' => '500', 'subfield' => ''},
  },
  
  # TK Labels
  'tk_labels' => {
    'attribution' => {'tag_number' => '561', 'subfield' => ''},
    'clan' => {'tag_number' => '561', 'subfield' => ''},
    'family' => {'tag_number' => '561', 'subfield' => ''},
    'outreach' => {'tag_number' => '540', 'subfield' => 'a'},
    'tk_multiple_community' => {'tag_number' => '561', 'subfield' => ''},
    'non_verified' => {'tag_number' => '506',  "indicator" => '1', 'subfield' => ''},
    'verified' => {'tag_number' => '506', "indicator" => '1', 'subfield' => ''},
    'non_commercial' => {'tag_number' => '540', 'subfield' => ''},
    'commercial' => {'tag_number' => '540', 'subfield' => 'a'},
    'culturally_sensitive' => {'tag_number' => '506', "indicator" => '1', 'subfield' => ''},
    'community_voice' => {'tag_number' => '561', 'subfield' => ''},
    'community_use_only' => {'tag_number' => '540', 'subfield' => 'a'},
    'seasonal' => {'tag_number' => '506', "indicator" => '1', 'subfield' => ''},
    'women_general' => {'tag_number' => '506', "indicator" => '1', 'subfield' => ''},
    'men_general' => {'tag_number' => '506', "indicator" => '1', 'subfield' => ''},
    'men_restricted' => {'tag_number' => '506', "indicator" => '1', 'subfield' => ''},
    'women_restricted' => {'tag_number' => '506', "indicator" => '1', 'subfield' => ''},
    'secret_sacred' => {'tag_number' => '506', "indicator" => '1', 'subfield' => ''},
    'open_to_collaboration' => {'tag_number' => '540', 'subfield' => ''},
    'creative' => {'tag_number' => '561', 'subfield' => ''},
  },

  # BC Labels
  'bc_labels' => {
    'provenance' => {'tag_number' => '561', 'subfield' => ''},
    'commercialization' => {'tag_number' => '540', 'subfield' => ''},
    'non_commercial' => {'tag_number' => '540', 'subfield' => ''},
    'collaboration' => {'tag_number' => '540', 'subfield' => ''},
    'consent_verified' => {'tag_number' => '506', "indicator" => '1', 'subfield' => ''},
    'consent_non_verified' => {'tag_number' => '506', "indicator" => '1', 'subfield' => ''},
    'multiple_community' => {'tag_number' => '561', 'subfield' => ''},
    'research' => {'tag_number' => '540', 'subfield' => ''},
    'clan' => {'tag_number' => '561', 'subfield' => ''},
    'outreach' => {'tag_number' => '540', 'subfield' => ''}
  }
}

Permission.define("manage_localcontexts_records",
                  "The ability to create/update/delete Local Contexts Project records",
                  :level => "repository")

Permission.define("update_localcontexts_project_record",
                  "The ability to create/update/delete Local Contexts Project records",
                  :implied_by => 'manage_localcontexts_records',
                  :level => "global")

# Register our custom serialize steps.
EADSerializer.add_serialize_step(EADLocalContextsSerialize)
EAD3Serializer.add_serialize_step(EAD3LocalContextsSerialize)

# Uncomment when MARC mappings are finalized
# MARCSerializer.add_decorator(LocalContextsMARCSerialize)


# create the local contexts data directory if it does not already exist
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

# check the cache on startup
Thread.new do
  LocalContextsClient.new.check_cache
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
