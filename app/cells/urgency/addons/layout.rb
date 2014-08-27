# coding: utf-8
module Urgency::Addons::Layout
  class EditCell < Cell::Rails
    include SS::AddonFilter::EditCell
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

  class ViewCell < Cell::Rails
    include SS::AddonFilter::ViewCell
  end
end
