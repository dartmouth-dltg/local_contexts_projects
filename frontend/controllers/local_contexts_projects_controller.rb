require 'net/http'
require 'uri'
require 'aspace_logger'

class LocalContextsProjectsController < ApplicationController

  set_access_control "view_repository" => [:fetch_lc_project_data, :index, :show, :typeahead],
                      "update_local_contexts_project_record" => [:new, :edit, :create, :update, :delete]


  SEARCH_FACETS = ["local_contexts_project_u_sstr"]

  def fetch_lc_project_data
    project_id = params[:project_id]
    use_cache = params[:use_cache].nil? ? false : params[:use_cache]
    project_json = JSONModel::HTTP::get_json("/local_contexts_projects/get_local_contexts_api_data", {:id => project_id, :type => 'project', :use_cache =>  use_cache})

    if project_json.nil?
      render :json => {"error":"Something went wrong. Unable to fetch and/or parse data for this id."}
    else
      render :json => project_json
    end

  end

  def index
    @search_data = Search.for_type(session[:repo_id],
                                   "local_contexts_project",
                                   params_for_backend_search.merge({"facet[]" => SEARCH_FACETS}))
  end

  def show
    @local_contexts_project = JSONModel(:local_contexts_project).find(params[:id], "resolve[]" => ["linked_record"])
  end

  def new
    @local_contexts_project = JSONModel(:local_contexts_project).new._always_valid!
    render_aspace_partial :partial => "local_contexts_projects/new" if inline?
  end

  def edit
    @local_contexts_project = JSONModel(:local_contexts_project).find(params[:id])
  end

  def create
    handle_crud(:instance => :local_contexts_project,
                :model => JSONModel(:local_contexts_project),
                :on_invalid => ->() { render action: "new" },
                :on_valid => ->(id) {
                    flash[:success] = I18n.t("local_contexts_project._frontend.messages.created")
                    redirect_to(:controller => :local_contexts_projects,
                                :action => :edit,
                                :id => id) })
  end

  def update
    handle_crud(:instance => :local_contexts_project,
                :model => JSONModel(:local_contexts_project),
                :obj => JSONModel(:local_contexts_project).find(params[:id]),
                :on_invalid => ->() {
                  return render action: "edit"
                },
                :on_valid => ->(id) {
                  flash[:success] = I18n.t("local_contexts_project._frontend.messages.updated")
                  redirect_to :controller => :local_contexts_projects, :action => :edit, :id => id
                })
  end

  def delete
    local_contexts_project = JSONModel(:local_contexts_project).find(params[:id])
    begin
      local_contexts_project.delete
    rescue ConflictException => e
      flash[:error] = I18n.t("local_contexts_project._frontend.messages.delete_conflict", :error => I18n.t("errors.#{e.conflicts}", :default => e.message))
      return redirect_to(:controller => :local_contexts_projects, :action => :show, :id => params[:id])
    end

    flash[:success] = I18n.t("local_contexts_project._frontend.messages.deleted")
    redirect_to(:controller => :local_contexts_projects, :action => :index, :deleted_uri => local_contexts_project.uri)
  end

  def typeahead
    search_params = params_for_backend_search

    search_params = search_params.merge("sort" => "local_contexts_project_typeahead_sort_key_u_sort asc")

    render :json => Search.all(session[:repo_id], search_params)
  end

end
