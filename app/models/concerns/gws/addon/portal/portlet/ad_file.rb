module Gws::Addon::Portal::Portlet
  module AdFile
    extend ActiveSupport::Concern
    extend SS::Addon

    set_addon_type :gws_portlet

    DEFAULT_AD_FILE_LIMIT = 5

    included do
      attr_accessor :link_urls

      embeds_ids :ad_files, class_name: "SS::File"
      permit_params ad_file_ids: [], link_urls: {}

      validate :validate_files_limit

      before_save :save_files
      after_destroy :destroy_files
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

    private

    def save_files
      return unless link_urls

      ids = []
      ad_files.each do |file|
        file = file.becomes_with(SS::LinkFile)
        file.update!(
          model: model_name.i18n_key, state: "closed", owner_item: self,
          link_url: link_urls[file.id.to_s]
        )
        ids << file.id
      end
      self.ad_file_ids = ids

      del_ids = ad_file_ids_was.to_a - ids
      SS::LinkFile.all.unscoped.in(id: del_ids).destroy_all
    end

    def destroy_files
      SS::LinkFile.all.unscoped.in(id: ad_file_ids).destroy_all
    end

    def validate_files_limit
      limit = self.class.ad_file_limit
      if ad_files.count > limit
        errors.add :ad_files, :too_many_files, limit: limit
      end
    end
  end
end
