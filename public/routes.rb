Rails.application.routes.draw do
  get 'local_context/fetch/fetch_lc_project_data', to: 'local_context#fetch_lc_project_data'
end
