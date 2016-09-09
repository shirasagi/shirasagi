module Multilingual::Addon
  module Content
    extend ActiveSupport::Concern
    extend SS::Translation

    included do
      class_variable_set(:@@_native_only_fields, [])
      class_variable_set(:@@_show_foreign_addons, [])
      class_variable_set(:@@_swap_foreign_addons, [])

      belongs_to :native, foreign_key: "native_id", class_name: self.to_s
      has_many :foreigners, foreign_key: "native_id", class_name: self.to_s, dependent: :destroy
      permit_params :native_id

      define_method(:native?) { native.blank? }
      define_method(:foreigner?) { native.present? }

      validate :validate_multilingual_filename
      before_validation :remove_native_only_fields
      after_save :rename_foreigners, if: ->{ @db_changes }

      foreign_field :name, :index_name, :name_for_index
      foreign_field :layout, :layout_id
      foreign_field :url, :full_url, :path
      foreign_field :summary, :summary_html, :description, :keywords
      foreign_field :upper_html, :loop_html, :lower_html
      foreign_field :released
      #foreign_field :created, :updated

      show_foreign_addon Cms::Addon::Meta
      show_foreign_addon Cms::Addon::Release
      show_foreign_addon Cms::Addon::GroupPermission
      show_foreign_addon Cms::Addon::Html
      swap_foreign_addon Cms::Addon::NodeList, Multilingual::Addon::Swap::PartialHtml
      swap_foreign_addon Cms::Addon::PageList, Multilingual::Addon::Swap::PartialHtml

      native_only_field :order, :category_ids
    end

    def lang
      langs = Multilingual::Node::Lang.site(site).all.map(&:filename)
      filename.scan(/^(#{langs.join("|")})\//).flatten.first
    end

    def request_lang
      Multilingual::Initializer.lang
    end

    def request_preview
      Multilingual::Initializer.preview
    end

    #def native
    #  langs = Multilingual::Node::Lang.site(site).all.map(&:filename)
    #  return nil if filename !~ /^(#{langs.join("|")})\//
    #  self.class.site(site).where(filename: filename.sub(/^(#{langs.join("|")})\//, "")).first
    #end

    def foreign(lang)
      return nil unless site

      if @foreign_first_access
        @foreign
      else
        @foreign_first_access = true
        @foreign = foreigners.site(site).where(filename: "#{lang}/#{filename}").first
        #@foreign = self.class.site(site).where(filename: "#{lang}/#{filename}").first
      end
    end

    def serve_static_file?
      native? ? super : false
    end

    def rename_foreigners
      return if foreigner?
      return unless @db_changes["filename"]
      return unless @db_changes["filename"][0]

      src, dst = @db_changes["filename"]
      foreigners.each do |item|
        dst_filename = item.filename.sub(src, dst)

        item.filename = dst_filename
        item.depth = dst_filename.scan("/").size + 1
        item.save!
      end
    end

    def content_class
      nil
    end

    def content_name
      nil
    end

    def validate_multilingual_filename
      return if native_id

      langs = Multilingual::Node::Lang.where(site_id: site_id).all.map(&:filename)
      langs.each do |lang|
        item = content_class.where(site_id: site_id, filename: "#{lang}/#{filename}").first
        branches = item.try(:branches)

        #if item
        #  errors.add :base, "#{item.filename} " + I18n.t("errors.messages.multilingual_content_exist")
        #end

        if branches.present?
          branches.each do |item|
            errors.add :base, "#{item.filename} " + I18n.t("errors.messages.multilingual_content_exist")
          end
        end
      end
    end

    def private_show_path
      return super if native?

      item = native
      node = item.parent
      lang = filename.sub(/\/.*$/, "")

      helper_mod = Rails.application.routes.url_helpers
      if node
        show_path = "multilingual_node_#{content_name}_path"
        helper_mod.send(show_path, site: site, cid: node.id, native_id: native.id, lang: lang, id: id)
      else
        show_path = "multilingual_#{content_name}_path"
        helper_mod.send(show_path, site: site, native_id: native.id, lang: lang, id: id)
      end
    end

    def remove_native_only_fields
      return unless native_id

      self.class.native_only_fields.each do |name|
        self.send("#{name}=", nil)
      end
    end

    module ClassMethods
      def foreign_field(*args)
        args.each do |name|
          next unless method_defined?(name)
          alias_method "_original_#{name}", name.to_s
          define_method(name) do
            if request_lang
              item = foreign(request_lang)

              if item && (item.public? || request_preview)
                return item.send(name)
              end
            end
            send("_original_#{name}")
          end
        end
      end

      def native_only_field(*args)
        args.each do |name|
          next unless method_defined?("#{name}=")

          fields = class_variable_get(:@@_native_only_fields)
          next if fields.include?(name)
          fields << name
          class_variable_set(:@@_native_only_fields, fields)
        end
      end

      def native_only_fields
        class_variable_get(:@@_native_only_fields)
      end

      def foreign_addons
        ads = []
        show_ads = class_variable_get(:@@_show_foreign_addons)
        swap_ads = class_variable_get(:@@_swap_foreign_addons)

        addons.each do |ad|
          show_ad = show_ads.select { |show_ad| show_ad.klass == ad.klass }.first
          src_ad, dst_ad = swap_ads.select { |src_mod, dst_mod| src_mod.klass == ad.klass }.first

          if show_ad
            ads << ad
          elsif src_ad
            ads << dst_ad
          end
        end
        ads.uniq(&:klass)
      end

      def swap_foreign_addon(src, dst)
        ads = class_variable_get(:@@_swap_foreign_addons)
        ads << [SS::Addon::Name.new(src), SS::Addon::Name.new(dst)]
        ads = ads.uniq { |ad| ad[0].klass }
        class_variable_set(:@@_swap_foreign_addons, ads)
      end

      def show_foreign_addon(mod)
        ads = class_variable_get(:@@_show_foreign_addons)
        ads << SS::Addon::Name.new(mod)
        ads = ads.uniq(&:klass)
        class_variable_set(:@@_show_foreign_addons, ads)
      end
    end
  end
end
