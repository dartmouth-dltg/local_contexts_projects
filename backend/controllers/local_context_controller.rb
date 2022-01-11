require 'aspace_logger'
class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/plugins/local_context/get_local_contexts_api_data')
  .description("Fetch the data associated with a Local Contexts project, user, researcher, or institution id from Local Contexts API")
  .params(["id", String, "The Local Contexts id"],
          ["type", String, "The type of object to fetch"])
  .permissions([])
  .returns([200, "json from the local contexts api"]) \
  do
    client = LocalContextsClient.new
    api_response = client.get_data_from_api(params[:id], params[:type])
    json_response(api_response)
  end

end
