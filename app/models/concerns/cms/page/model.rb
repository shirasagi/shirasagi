# coding: utf-8
module Cms::Page::Model
  extend ActiveSupport::Concern
  extend SS::Translation
  include Cms::Page::Feature
  include Cms::Reference::Layout

  included do
    store_in collection: "cms_pages"
    set_permission_name "cms_pages"

    field :route, type: String, default: ->{ "cms/page" }
    permit_params :route

    after_save :rename_file, if: ->{ @db_changes }
    after_save :generate_file, if: ->{ @db_changes }
    after_save :remove_file, if: ->{ @db_changes && @db_changes["state"] && !public? }
    after_destroy :remove_file
  end

  public
    def becomes_with_route
      klass = route.camelize.constantize rescue nil
      return self unless klass

      item = klass.new
      item.instance_variable_set(:@new_record, nil) unless new_record?
      instance_variables.each {|k| item.instance_variable_set k, instance_variable_get(k) }
      item
    end

    def generate_file
      return unless public?
      Cms::Task::PagesController.new.generate_file(self)
    end

  private
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
