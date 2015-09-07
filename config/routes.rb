Rails.application.routes.draw do
  namespace :foreman_one_click_deploy, path: 'stagingil' do
    constraints(:id => /[^\/]+/) do
      resources :hosts do
        collection do
          post 'process_hostgroup'
          post 'compute_resource_selected'
          post 'hostgroup_or_environment_selected'
          # get 'new'
          post 'interfaces'
          post 'template_used'
        end
        member do
          get 'clone'
        end
      end
    end
  end
end