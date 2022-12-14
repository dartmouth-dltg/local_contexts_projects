ArchivesSpace::Application.routes.draw do
  [AppConfig[:frontend_proxy_prefix], AppConfig[:frontend_prefix]].uniq.each do |prefix|
    scope prefix do
      match('plugins/local_contexts_projects/fetch_lc_project_data' => 'local_contexts_projects#fetch_lc_project_data', :via => [:get])
      match('plugins/local_contexts_projects/search/typeahead' => 'local_contexts_projects#typeahead', :via => [:get])
      match('plugins/local_contexts_projects' => 'local_contexts_projects#index', :via => [:get])
      match('plugins/local_contexts_projects/reset_cache' => 'local_contexts_projects#reset_cache', :via => [:post])
      match('plugins/local_contexts_projects/clear_cache' => 'local_contexts_projects#clear_cache', :via => [:post])
      resources :local_contexts_projects
      match('plugins/local_contexts_projects/create' => 'local_contexts_projects#create', :via => [:post])
      match('plugins/local_contexts_projects/new' => 'local_contexts_projects#new', :via => [:get])
      match('plugins/local_contexts_projects/show' => 'local_contexts_projects#show', :via => [:get])
      match('plugins/local_contexts_projects/:id/delete' => 'local_contexts_projects#delete', :via => [:post])
    end
  end
end
