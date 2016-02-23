module Cms::Addon
  module BodyLayoutHtml
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :html, type: String
      permit_params :html
    end

    def body_layout_addons
      addons = {}
      Cms::Page.addons.each do |addon|
        route = addon.instance_variable_get("@name")
        next unless addon.view_file
        next if route == "cms/body"
        next if route == "cms/body_part"
        addons[route] = addon
      end
      addons
    end

    def body_layout_addon_options
      body_layout_addons.map do |route, addon|
        [ addon.name, "{{ addon \"#{route}\" }}" ]
      end
    end
  end
end
