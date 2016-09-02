module Multilingual::Addon
  module Node
    extend ActiveSupport::Concern
    extend SS::Addon
    include Multilingual::Addon::Content

    included do
      #inqury
      foreign_field :inquiry_html
      foreign_field :inquiry_sent_html
      foreign_field :inquiry_results_html

      #facility
      foreign_field :kana
      foreign_field :postcode
      foreign_field :address
      foreign_field :tel
      foreign_field :fax
      foreign_field :related_url
      foreign_field :additional_info

      show_foreign_addon Inquiry::Addon::Message

      native_only_field :shortcut
    end

    def content_class
      Cms::Node
    end

    def content_name
      "node"
    end

    def rename_foreigners
      return if foreigner?
      return unless @db_changes["filename"]
      return unless @db_changes["filename"][0]

      src, dst = @db_changes["filename"]
      langs = Multilingual::Node::Lang.site(site).all.map(&:filename)
      langs.each do |lang|
        item = foreigners.where(filename: "#{lang}/#{src}").first
        if item
          dst_filename = item.filename.sub(src, dst)

          item.filename = dst_filename
          item.depth = dst_filename.scan("/").size + 1
          item.save!
        else
          [Cms::Node, Cms::Page, Cms::Part, Cms::Layout].each do |content|
            content.site(site).where(filename: /^#{lang}\/#{src}\//).each do |item|
              dst_filename = item.filename.sub(/^#{lang}\/#{src}\//, "#{lang}/#{dst}\/")
              item.set(
                filename: dst_filename,
                depth: dst_filename.scan("/").size + 1
              )
            end
          end
        end
      end
    end

    def destroy_children
      return if foreigner?
      super
    end
  end
end
