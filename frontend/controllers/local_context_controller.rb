require 'net/http'
require 'uri'
require 'aspace_logger'

class LocalContextController < ApplicationController

set_access_control "view_repository" => [:fetch_lc_data]

  def fetch_lc_data
    logger = Logger.new($stderr)
    api_base_url = AppConfig[:local_context_api]
    project_id = params[:project_id]

    uri = URI(File.join(api_base_url, 'projects', project_id, '?format=json'))
    logger.debug("LC URI: #{uri.inspect}")
    res = Net::HTTP.get_response(uri)
    logger.debug("LC_RESPONSE: #{res.inspect}")
    if res.is_a?(Net::HTTPSuccess)
      render :json => res.body
    else
      render :json => {"error":"Something went wrong. Unable to fetch and/or parse data for this project id."}
    end
  rescue Timeout::Error => e
    render :json => {"error":"Timeout attempting to fetch data from Local Contexts API. Unable to fetch and/or parse data for this project id. Error message: #{e}"}
  end
end
