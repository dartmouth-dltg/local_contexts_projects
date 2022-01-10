require 'net/http'
require 'uri'
require 'aspace_logger'

class LocalContextController < ApplicationController

set_access_control "view_repository" => [:fetch_lc_data]

  def fetch_lc_data
    api_base_url = AppConfig[:local_context_api]
    project_id = params[:project_id]

    uri = URI(File.join(api_base_url, 'projects', project_id, '?format=json'))
    res = Net::HTTP.get_response(uri)

    if res.is_a?(Net::HTTPSuccess)
      render :json => res.body
    else
      render :json => {"error":"Something went wrong. Unable to fetch and/or parse data for this project id."}
    end
  end
end
