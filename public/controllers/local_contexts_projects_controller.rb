require 'aspace_logger'
class LocalContextsProjectsController < ApplicationController

  # answer with a JSON 401 (not the login page) when the PUI requires authentication
  json_response_for :fetch_lc_project_data

  skip_before_action  :verify_authenticity_token

  def fetch_lc_project_data
    unless params[:id].nil?
      type = params[:type].nil? ? 'project' : params[:type]
      # always use the cache on the public side; the backend refreshes it when stale
      res = archivesspace.get_data_from_local_contexts_api(params[:id], type, true)
      render :json => res
    end
  end
  
end
