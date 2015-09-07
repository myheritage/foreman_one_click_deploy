# ForemanOneClickDeploy

*Introdction here*

## Installation

See [How_to_Install_a_Plugin](http://projects.theforeman.org/projects/foreman/wiki/How_to_Install_a_Plugin)
for how to install Foreman plugins

## Usage

*Usage here*

### Plugin Settings
*one_click_deploy_golden_server* - The name of the VM that we will create the golder image from. Needs to be in foreman
*one_click_deploy_golden_image_min_backups* - Retention of how many images do we want to keep back of the image
*one_click_deploy_computeresource_shutdown_string* - How the ComputeResource responds to state api call when the VM is turned off (i.e: Openstask - SHUTOFF) (Default: value for OpenStack- SHUTOFF)    

*one_click_deploy_golden_image_shutdown_ticks* - Number of time we will address the ComputeResource to check if the VM has been halted (0 for indefinatly - NOT RECOMENDED) (Default: 24)
*one_click_deploy_golden_image_shutdown_sleep_interval* - Number of seconds to sleep between each check against the ComputeResource (0 ti disable sleeping - NOT RECOMENDED) (Default: 5)
*one_click_deploy_golden_image_image_from_volume_ticks* - Number of time we will address the ComputeResource to check if the new image has been created from the volume (0 for indefinatly - NOT RECOMENDED) (Default: 24)
*one_click_deploy_golden_image_image_from_volume_sleep_interval* - Number of seconds to sleep between each check against the ComputeResource (0 ti disable sleeping - NOT RECOMENDED) (Default: 5)

## TODO

*Todo list here*

## Contributing

Fork and send a Pull Request. Thanks!

## Copyright

Copyright (c) *year* *your name*

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

