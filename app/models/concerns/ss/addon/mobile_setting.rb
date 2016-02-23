module SS::Addon
  module MobileSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :mobile_state, type: String
      field :mobile_location, type: String
      field :mobile_css, type: SS::Extensions::Words
      field :trans_sid, type: String
      permit_params :mobile_state, :mobile_location, :mobile_css, :trans_sid
      before_validation :normalize_mobile_location
      validates :mobile_state, inclusion: { in: %w(disabled enabled) }, if: ->{ mobile_state.present? }
      validates :trans_sid, inclusion: { in: %w(none mobile always) }, if: ->{ trans_sid.present? }
    end

    private
      def normalize_mobile_location
        return if mobile_location.blank?
        self.mobile_location = "/#{mobile_location}" unless mobile_location.start_with?('/')
        self.mobile_location = mobile_location[0, mobile_location.length - 1] if mobile_location.end_with?('/')
      end

    public
      def mobile_state
        return 'enabled' unless value = self.attributes["mobile_state"]
        value
      end

      def mobile_location
        return '/mobile' unless value = self.attributes["mobile_location"]
        value
      end

      def mobile_css
        return default_mobile_css unless value = self.attributes["mobile_css"]
        value
      end

      def default_mobile_css
        dir = "#{self.path}/css"
        css = Fs.exists?("#{dir}/mobile.css") || Fs.exists?("#{dir}/mobile.scss")
        css = css ? '/css/mobile.css' : '%{assets_prefix}/cms/mobile.css'
        [css]
      end

      def trans_sid
        return 'none' unless value = self.attributes["trans_sid"]
        value
      end

      def mobile_disabled?
        !mobile_enabled?
      end

      def mobile_enabled?
        mobile_state == 'enabled' && mobile_location.present?
      end

      def mobile_state_options
        %w(disabled enabled).map { |m| [ I18n.t("views.options.state.#{m}"), m ] }.to_a
      end

      def trans_sid_options
        %w(none mobile always).map { |m| [ I18n.t("views.options.trans_sid.#{m}"), m ] }.to_a
      end
  end
end
