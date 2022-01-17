ArchivesSpace::Application.routes.draw do
  match('/plugins/local_contexts_projects/fetch_lc_project_data' => 'local_contexts_projects#fetch_lc_project_data', :via => [:get])
  match('/plugins/local_contexts_projects/search/typeahead' => 'local_contexts_projects#typeahead', :via => [:get])
  match('/plugins/local_contexts_projects' => 'local_contexts_projects#index', :via => [:get])
  resources :local_contexts_projects
  match('/plugins/local_contexts_projects/create' => 'local_contexts_projects#create', :via => [:post])
  match('/plugins/local_contexts_projects/new' => 'local_contexts_projects#new', :via => [:get])
  match('/plugins/local_contexts_projects/show' => 'local_contexts_projects#show', :via => [:get])
  match('/plugins/local_contexts_projects/:id/delete' => 'local_contexts_projects#delete', :via => [:post])
end
