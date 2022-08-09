require 'aspace_logger'
class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/local_contexts_projects/get_local_contexts_api_data')
  .description("Fetch the data associated with a Local Contexts project, user, researcher, or institution id from Local Contexts API")
  .params(["id", String, "The Local Contexts id"],
          ["type", String, "The type of object to fetch"],
          ["use_cache", BooleanParam, "Flag to indicate whether cached response should be used"])
  .permissions([])
  .returns([200, "json from the local contexts api"]) \
  do
    client = LocalContextsClient.new
    api_response = client.get_data_from_local_contexts_api(params[:id], params[:type], params[:use_cache])
    json_response(api_response)
  end

  Endpoint.post('/local_contexts_projects/reset_cache')
  .description("Clear Local Contexts Projects file cache")
  .params(["project_id", String, "Project id"])
  .permissions([:update_localcontexts_project_record])
  .returns([200, :updated]) \
  do
    client = LocalContextsClient.new
    response = client.reset_cache(params[:project_id])
    json_response(response)
  end

  Endpoint.post('/local_contexts_projects/clear_cache')
  .description("Clear Local Contexts Projects file cache")
  .params()
  .permissions([:update_localcontexts_project_record])
  .returns([200, :updated]) \
  do
    client = LocalContextsClient.new
    response = client.clear_cache
    json_response(response)
  end

  Endpoint.post('/local_contexts_projects/:id')
    .description("Update a Local Contexts Project")
    .params(["id", :id],
            ["local_contexts_project", JSONModel(:local_contexts_project), "The updated record", :body => true])
    .permissions([:update_localcontexts_project_record])
    .returns([200, :updated]) \
  do
    handle_update(LocalContextsProject, params[:id], params[:local_contexts_project])
  end


  Endpoint.post('/local_contexts_projects')
    .description("Create an Local Contexts Project")
    .params(["local_contexts_project", JSONModel(:local_contexts_project), "The record to create", :body => true])
    .permissions([:update_localcontexts_project_record])
    .returns([200, :created]) \
  do
    handle_create(LocalContextsProject, params[:local_contexts_project])
  end


  Endpoint.get('/local_contexts_projects')
    .description("Get a list of Local Contexts Projects")
    .params()
    .paginated(true)
    .permissions([])
    .returns([200, "[(:local_contexts_project)]"]) \
  do
    handle_listing(LocalContextsProject, params)
  end


  Endpoint.get('/local_contexts_projects/:id')
    .description("Get a Local Contexts Project by ID")
    .params(["id", :id],
            ["resolve", :resolve])
    .permissions([])
    .returns([200, "(:local_contexts_project)"]) \
  do
    json = LocalContextsProject.to_jsonmodel(params[:id])
    json_response(resolve_references(json, params[:resolve]))
  end


  Endpoint.delete('/local_contexts_projects/:id')
    .description("Delete a Local Contexts Project")
    .params(["id", :id])
    .permissions([:update_localcontexts_project_record])
    .returns([200, :deleted]) \
  do
    handle_delete(LocalContextsProject, params[:id])
  end

end
