class LocalContextController < ApplicationController

  skip_before_action  :verify_authenticity_token

  def fetch_lc_project_data
    id = params.fetch(:id, nil)
    type = 'project'
    get_data_from_api(id, type)
  end

  private

  def get_data_from_api(id, type)
    uri = "/plugins/local_context/get_local_contexts_api_data",
    @criteria = {:id => id, :type => type}
    if id && type
      begin
        render json: #FIXME: Need to hit the backend directly.
      rescue RecordNotFound
        render json: {}, status: 404
      end
    else
    end
  end

end
