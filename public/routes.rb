ArchivesSpacePublic::Application.routes.draw do
  match 'local_context/fetch_lc_project_data' => 'local_context#fetch_lc_project_data', :via => [:get]
end
