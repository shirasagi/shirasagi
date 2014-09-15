# coding: utf-8
module Cms::Page::Model
  extend ActiveSupport::Concern
  extend SS::Translation
  extend SS::Translation
  include Cms::Content
  include Cms::Reference::Layout

  included do
    store_in collection: "cms_pages"
    set_permission_name "cms_pages"

    field :route, type: String, default: ->{ "cms/page" }
    field :released, type: DateTime

    embeds_ids :categories, class_name: "Cms::Node"

    permit_params category_ids: []

    after_save :rename_file, if: ->{ @db_changes }
    after_save :generate_file, if: ->{ @db_changes }
    after_save :remove_file, if: ->{ @db_changes && @db_changes["state"] && !public? }
    after_destroy :remove_file
  end

  public
    def public_node?
      return true unless dirname
      Cms::Node.where(site_id: site_id).in_path(dirname).ne(state: "public").size == 0
    end

    def date
      released || updated || created
    end

    def generate_file
      return unless public?
      Cms::Task::PagesController.new.generate_file(self)
    end

  private
    def fix_extname
      ".html"
    end

    def rename_file
      return unless @db_changes["filename"]
      return unless @db_changes["filename"][0]

      src = "#{site.path}/#{@db_changes['filename'][0]}"
      dst = "#{site.path}/#{@db_changes['filename'][1]}"
      Fs.mv src, dst if Fs.exists?(src)
    end

    def remove_file
      Fs.rm_rf path
    end
end
