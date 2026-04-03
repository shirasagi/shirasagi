module Gws::Addon::Portal::Portlet
  module AdFile
    extend ActiveSupport::Concern
    extend SS::Addon
    include Fs::FilePreviewable

    set_addon_type :gws_portlet

    DEFAULT_AD_FILE_LIMIT = 5

    included do
      embeds_many :ad_links, class_name: "SS::LinkItem", cascade_callbacks: true, validate: true

      permit_params ad_links: %i[id name url file_id target state]

      after_find do
        if __selected_fields.nil? || __selected_fields.key?("ad_links")
          @_ad_links_before_change = ad_links.map(&:dup)
        end
      end

      before_validation :normalize_ad_links

      validates :ad_links, length: { maximum: ad_file_limit }

      before_save :ad_delete_unlinked_files
    end

    module ClassMethods
      def ad_file_limit
        limit = SS.config.gws.portal["portlet_settings"]["ad"]["image_limit"].to_i
        if limit <= 0
          limit = DEFAULT_AD_FILE_LIMIT
        end

        limit
      end
    end

    def ad_links_was
      return [] if new_record?
      @_ad_links_before_change || []
    end

    private

    def normalize_ad_links
      return if self.frozen?
      return if ad_links.blank?

      self.ad_links = ad_links.reject { blank_ad_link?(_1) }
    end

    def blank_ad_link?(ad_link)
      ad_link.name.blank? && ad_link.url.blank? && ad_link.file.blank?
    end

    def file_previewable?(file, site:, user:, member:)
      if user.blank?
        return super
      end

      ad_link = ad_links.where(file_id: file.id).first
      unless ad_link
        return super
      end

      ad_link.state == "show"
    end

    def ad_delete_unlinked_files
      return if new_record?

      file_ids_is = []
      self.ad_links.each do |ad_link|
        file_ids_is << ad_link.file_id
      end
      file_ids_is.compact!
      file_ids_is.uniq!

      file_ids_was = []
      self.ad_links_was.each do |ad_link|
        file_ids_was << ad_link.file_id
      end
      file_ids_was.compact!
      file_ids_was.uniq!

      unlinked_file_ids = file_ids_was - file_ids_is
      Cms::Reference::Files::Utils.delete_files(self, unlinked_file_ids)
    end
  end
end
