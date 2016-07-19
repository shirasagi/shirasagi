module Board::Addon
  module GooglePersonFinderSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :gpf_state, type: String
      field :gpf_repository, type: String
      field :gpf_domain_name, type: String
      field :gpf_api_key, type: String
      field :gpf_mode_cache, type: Hash
      attr_accessor :in_gpf_api_key

      permit_params :gpf_state, :gpf_repository, :gpf_domain_name, :in_gpf_api_key

      before_validation :set_gpf_api_key
      validates :gpf_state, inclusion: { in: %w(enabled disabled) }, if: ->{ gpf_state.present? }
    end

    def accessor
      Google::PersonFinder.new(repository: gpf_repository, domain_name: gpf_domain_name, api_key: SS::Crypt.decrypt(gpf_api_key))
    end

    def gpf_state_options
      %w(disabled enabled).map { |m| [ I18n.t("board.options.gpf_state.#{m}"), m ] }.to_a
    end

    def gpf_enabled?
      gpf_state == 'enabled'
    end

    def gpf_mode
      update_mode_cache if self.gpf_mode_cache.blank? || self.gpf_mode_cache['updated'] + 1.hour < Time.zone.now
      self.gpf_mode_cache['mode']
    end

    private
      def set_gpf_api_key
        self.gpf_api_key = SS::Crypt.encrypt(in_gpf_api_key) if in_gpf_api_key.present?
      end

      def raw_mode
        accessor.mode.to_s
      end

      def update_mode_cache
        new_value = {
          'mode' => raw_mode,
          'updated' => Time.zone.now
        }
        self.update(gpf_mode_cache: new_value)
      end
  end
end
