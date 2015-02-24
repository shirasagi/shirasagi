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

    def validate_destination_filename(dst)
      dst_dir = ::File.dirname(dst).sub(/^\.$/, "")

      return errors.add :filename, :empty if dst.blank?
      return errors.add :filename, :invalid if dst !~ /^([\w\-]+\/)*[\w\-]+(#{fix_extname})?$/

      return errors.add :base, :same_filename if filename == dst
      return errors.add :filename, :taken if self.class.where(site_id: site_id, filename: dst).first
      return errors.add :base, :exist_physical_file if Fs.exists?("#{site.path}/#{dst}")

      if dst_dir.present?
        dst_parent = Cms::Node.where(site_id: site_id, filename: dst_dir).first

        return errors.add :base, :not_found_parent_node if dst_parent.blank?
        # add Authority check if necessary
      else
        return errors.add :base, :not_cms_page_in_root if route != "cms/page"
      end
    end

    def move(dst)
      validate_destination_filename(dst)
      return false unless errors.empty?

      @cur_node = nil
      @basename = dst
      save
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
