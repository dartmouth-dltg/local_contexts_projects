class LocalContextsProjectsController < ApplicationController

  skip_before_action  :verify_authenticity_token

  def fetch_lc_project_data
    unless params[:id].nil?
      type = params[:type].nil? ? 'project' : params[:type]
      res = archivesspace.get_data_from_local_contexts_api(params[:id], type)
      render :json => res
    end
  end

end
