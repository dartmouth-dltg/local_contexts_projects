ArchivesSpace::Application.routes.draw do
  match('/plugins/local_context/fetch_lc_project_data' => 'local_context#fetch_lc_project_data', :via => [:get])
end
