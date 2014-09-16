# coding: utf-8
module Cms::Part::Model
  extend ActiveSupport::Concern
  extend SS::Translation
  include Cms::Content

  included do |mod|
    store_in collection: "cms_parts"
    set_permission_name "cms_parts"

    field :route, type: String
    field :mobile_view, type: String, default: "show"
    permit_params :route, :mobile_view

    after_save :update_layouts
  end

  public
    def route_options
      Cms::Part.plugins
    end

    def becomes_with_route
      super route.sub("/", "/part/")
    end

    def mobile_view_options
      [%w(表示 show), %w(非表示 hide)]
    end

  private
    def fix_extname
      ".part.html"
    end

    def update_layouts
      return if @db_changes.blank?

      cond = { :part_paths.in => ( @db_changes["filename"] || [filename] ) }

      Cms::Layout.site(site).public.where(cond).each do |layout|
        layout.generate_file
      end
    end
end
