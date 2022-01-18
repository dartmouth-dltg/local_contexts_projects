Rails.application.routes.draw do
  get 'local_contexts_projects/fetch/fetch_lc_project_data', to: 'local_contexts_projects#fetch_lc_project_data'
end
