module Urgency::Agents::Addons::Layout
  class EditController < ApplicationController
    include SS::AddonFilter::Edit
    helper_method :selectable_layouts_options

    private
      def selectable_layouts_options
        opts = []
        Cms::Layout.site(@cur_site).each do |layout|
          opts << [ layout.name, layout.id ]
        end
        opts
      end
  end
end
