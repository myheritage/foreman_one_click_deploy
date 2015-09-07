Deface::Override.new(
    :virtual_path => 'hosts/_form',
    :name => 'hide_parameters_data',
    :add_to_attributes => 'a[href="#params"]',
    :attributes => {
        :class => "one_click_hide"
    }
)

Deface::Override.new(
    :virtual_path => 'hosts/_form',
    :name => 'hide_network_data',
    :add_to_attributes => 'a[href="#network"]',
    :attributes => {
        :class => "one_click_hide"
    }
)

Deface::Override.new(
    :virtual_path => 'hosts/_form',
    :name => 'hide_os_data',
    :add_to_attributes => 'a[href="#os"]',
    :attributes => {
        :class => "one_click_hide"
    }
)

Deface::Override.new(
    :virtual_path => 'hosts/_form',
    :name => 'hide_info_data',
    :add_to_attributes => 'a[href="#info"]',
    :attributes => {
        :class => "one_click_hide"
    }
)

Deface::Override.new(
    :virtual_path => 'hosts/_form',
    :name => "move_comments",
    :insert_after => "div#puppet_klasses",
    :cut => "erb[loud]:contains('textarea_f f, :comment')"
)

Deface::Override.new(
    :virtual_path => 'hosts/_form',
    :name => 'hide_environment',
    :add_to_attributes => 'div#primary > div:last-child.clearfix',
    :attributes => {
        :class => "one_click_hide"
    }
)
Deface::Override.new(
    :virtual_path => 'layouts/base',
    :name => 'add_css',
    :insert_after => 'meta[name=viewport]',
    :text => '<%= stylesheet "one_click_deploy" %>'
)
