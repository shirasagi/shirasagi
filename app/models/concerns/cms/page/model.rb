module Cms::Page::Model
  extend ActiveSupport::Concern
  extend SS::Translation
  include Cms::Content
  include Cms::Reference::Layout

  included do
    store_in collection: "cms_pages"
    set_permission_name "cms_pages"

    #text_index :name, :html

    field :route, type: String, default: ->{ "cms/page" }

    embeds_ids :categories, class_name: "Cms::Node"

    permit_params category_ids: []

    after_validation :set_released, if: -> { public? }
    after_save :rename_file, if: ->{ @db_changes }
    after_save :generate_file, if: ->{ @db_changes }
    after_save :remove_file, if: ->{ @db_changes && @db_changes["state"] && !public? }
    after_destroy :remove_file
  end

  public
    def date
      released || updated || created
    end

    def generate_file
      return unless serve_static_file?
      return unless public?
      return unless public_node?
      Cms::Agents::Tasks::PagesController.new.generate_page(self)
    end

  private
    def set_released
      self.released ||= Time.now
    end

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
