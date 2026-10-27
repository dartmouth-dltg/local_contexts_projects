require 'aspace_logger'
class LocalContextsProjectsController < ApplicationController

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
