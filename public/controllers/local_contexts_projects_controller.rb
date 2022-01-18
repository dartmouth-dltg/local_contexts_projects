class LocalContextsProjectsController < ApplicationController

  skip_before_action  :verify_authenticity_token

  def fetch_lc_project_data
    unless params[:id].nil?
      type = 'project'
      res = archivesspace.get_data_from_api(params[:id], type)
      render :json => res
    end
  end

end
