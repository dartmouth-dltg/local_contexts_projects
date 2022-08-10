class LocalContextsProjectsController < ApplicationController

  skip_before_action  :verify_authenticity_token

  def fetch_lc_project_data
    unless params[:id].nil?
      type = params[:type].nil? ? 'project' : params[:type]
      use_cache = params[:use_cache].nil? ? true : params[:use_cache]
      res = archivesspace.get_data_from_local_contexts_api(params[:id], type, use_cache)
      render :json => res
    end
  end

end
