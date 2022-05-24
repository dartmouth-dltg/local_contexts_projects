Rails.application.routes.draw do
  [AppConfig[:public_proxy_prefix], AppConfig[:public_prefix]].uniq.each do |prefix|
    scope prefix do
      get 'local_contexts_projects/fetch/fetch_lc_project_data', to: 'local_contexts_projects#fetch_lc_project_data'
    end
  end
end
