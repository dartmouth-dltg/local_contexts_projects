require 'net/http'
require 'uri'
require 'aspace_logger'

class LocalContextController < ApplicationController

set_access_control "view_repository" => [:fetch_lc_project_data]

  def fetch_lc_project_data
    project_id = params[:project_id]
    project_json = JSONModel::HTTP::get_json("/plugins/local_context/get_local_contexts_api_data", {:id => project_id, :type => 'project'})

    if project_json.nil?
      render :json => {"error":"Something went wrong. Unable to fetch and/or parse data for this id."}
    else
      render :json => project_json
    end

  end
end
