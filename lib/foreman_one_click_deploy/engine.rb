require 'deface'

module ForemanOneClickDeploy
  class Engine < ::Rails::Engine
    engine_name 'foreman_one_click_deploy'

    config.autoload_paths += Dir["#{config.root}/app/controllers/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/helpers/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/models/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/overrides"]

    # Add any db migrations
    initializer 'foreman_one_click_deploy.load_app_instance_data' do |app|
      app.config.paths['db/migrate'] += ForemanOneClickDeploy::Engine.paths['db/migrate'].existent
    end

    initializer 'foreman_one_click_deploy.register_plugin', after: :finisher_hook do |_app|
      Foreman::Plugin.register :foreman_one_click_deploy do
        requires_foreman '>= 1.9'

        # Add permissions
        security_block :foreman_one_click_deploy do
          permission :view_foreman_one_click_deploy, :'foreman_one_click_deploy/hosts' => [:new_action]
        end

        # Add a new role called 'Discovery' if it doesn't exist
        role 'ForemanOneClickDeploy', [:view_foreman_one_click_deploy]

        #add menu entry
        sub_menu :top_menu, :staging_il_menu, :caption => N_('One Click Deploy'), :after => :hosts_menu do
          menu :top_menu, :new_foreman_one_click_deploy_host,
               :caption =>  N_('New Host')
          # menu :top_menu, :foreman_staging_il_host,
          #      :url_hash => {:controller => :'foreman_staging_il/hosts', :action => :index},
          #      :caption => 'List StagingIL Servers'
        end

        # add dashboard widget
        widget 'foreman_one_click_deploy_widget', name: N_('Foreman plugin template widget'), sizex: 4, sizey: 1
      end
    end

    # Precompile any JS or CSS files under app/assets/
    # If requiring files from each other, list them explicitly here to avoid precompiling the same
    # content twice.
    assets_to_precompile =
      Dir.chdir(root) do
        Dir['app/assets/javascripts/**/*', 'app/assets/stylesheets/**/*'].map do |f|
          f.split(File::SEPARATOR, 4).last
        end
      end
    initializer 'foreman_one_click_deploy.assets.precompile' do |app|
      app.config.assets.precompile += assets_to_precompile
    end
    initializer 'foreman_one_click_deploy.configure_assets', group: :assets do
      SETTINGS[:foreman_one_click_deploy] = { assets: { precompile: assets_to_precompile } }
    end

    # Include concerns in this config.to_prepare block
    config.to_prepare do
      begin
        Host::Managed.send(:include, ForemanOneClickDeploy::HostExtensions)
        HostsHelper.send(:include, ForemanOneClickDeploy::HostsHelperExtensions)
      rescue => e
        Rails.logger.warn "ForemanOneClickDeploy: skipping engine hook (#{e})"
      end
    end

    rake_tasks do
      Rake::Task['db:seed'].enhance do
        ForemanOneClickDeploy::Engine.load_seed
      end
    end

    initializer 'foreman_one_click_deploy.register_gettext', after: :load_config_initializers do |_app|
      locale_dir = File.join(File.expand_path('../../..', __FILE__), 'locale')
      locale_domain = 'foreman_one_click_deploy'
      Foreman::Gettext::Support.add_text_domain locale_domain, locale_dir
    end
  end
end
