module SS::Addon
  module Translate::SiteSetting
    extend ActiveSupport::Concern
    extend SS::Addon
    include SS::Relation::File

    included do
      attr_accessor :request_word_limit_exceeded

      field :translate_state, type: String, default: "disabled"

      belongs_to :translate_source, class_name: "Translate::Lang"
      embeds_ids :translate_targets, class_name: "Translate::Lang"
      define_method(:translate_targets) do
        items = ::Translate::Lang.in(id: translate_target_ids).to_a
        translate_target_ids.map { |id| items.find { |item| item.id == id } }
      end

      field :translate_api, type: String
      field :translate_api_request_word_limit, type: Integer, default: 0
      field :translate_api_limit_exceeded_html, type: String

      # mock
      field :translate_mock_api_request_count, type: Integer, default: 0
      field :translate_mock_api_request_word_count, type: Integer, default: 0

      # microsoft translator text api
      field :translate_microsoft_api_key, type: String
      field :translate_microsoft_api_request_count, type: Integer, default: 0
      field :translate_microsoft_api_request_word_count, type: Integer, default: 0
      field :translate_microsoft_api_request_metered_usage, type: Integer, default: 0

      # google translation api
      field :translate_google_api_project_id, type: String
      belongs_to_file :translate_google_api_credential_file, static_state: "closed"
      field :translate_google_api_request_count, type: Integer, default: 0
      field :translate_google_api_request_word_count, type: Integer, default: 0

      permit_params :translate_state
      permit_params :translate_source_id
      permit_params translate_target_ids: []
      permit_params :translate_api
      permit_params :translate_api_request_word_limit
      permit_params :translate_api_limit_exceeded_html

      permit_params :translate_mock_api_request_count
      permit_params :translate_mock_api_request_word_count

      permit_params :translate_microsoft_api_key
      permit_params :translate_microsoft_api_request_count
      permit_params :translate_microsoft_api_request_word_count
      permit_params :translate_microsoft_api_request_metered_usage

      permit_params :translate_google_api_project_id
      permit_params :translate_google_api_request_count
      permit_params :translate_google_api_request_word_count

      validates :translate_api, presence: true, if: -> { translate_enabled? }
      validate :validate_translate_source, if: -> { translate_api.present? }
      validate :validate_translate_targets, if: -> { translate_api.present? }
    end

    private

    def validate_translate_source
      if translate_source.blank?
        self.errors.add :translate_source_id, :blank
        return
      end

      translate_source.cur_site = self
      if translate_source.api_code.blank?
        self.errors.add :translate_source_id, :unsupported_lang, name: translate_source.name
      end
    end

    def validate_translate_targets
      if translate_targets.blank?
        self.errors.add :translate_target_ids, :blank
        return
      end

      translate_targets.each do |item|
        item.cur_site = self
        if item.api_code.blank?
          self.errors.add :translate_target_ids, :unsupported_lang, name: item.name
        end
      end
    end

    public

    def translate_state_options
      [
        [I18n.t("ss.options.state.enabled"), "enabled"],
        [I18n.t("ss.options.state.disabled"), "disabled"],
      ]
    end

    def translate_api_options
      @_translate_api_options ||= SS.config.translate.api_options.map { |k, v| [v, k] }
    end

    def translate_enabled?
      translate_state == "enabled"
    end

    def translate_path(target)
      ::File.join(path, "translate", target)
    end

    def translate_location
      @translate_location ||= SS.config.translate.location
    end

    def translate_path
      ::File.join(url, translate_location)
    end

    def translate_url
      ::File.join(url, translate_location, "/")
    end

    def find_translate_target(code)
      translate_targets.select { |item| item.code == code }.first
    end
  end
end
