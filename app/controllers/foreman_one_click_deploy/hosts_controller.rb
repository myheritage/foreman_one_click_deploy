module ForemanOneClickDeploy
  # Example: Plugin's HostsController inherits from Foreman's HostsController
  class HostsController < ::HostsController
    # change layout if needed
    # layout 'foreman_one_click_deploy/layouts/new_layout'

    def new_action
      # automatically renders view/foreman_one_click_deploy/hosts/new_action
    end
  end
end
