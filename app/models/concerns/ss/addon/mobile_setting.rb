module SS::Addon
  module MobileSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      attr_accessor :in_mobile_size
      field :mobile_state, type: String
      field :mobile_size, type: Integer, default: 500 * 1_024 # 500kb
      field :mobile_location, type: String
      field :mobile_css, type: SS::Extensions::Words
      permit_params :mobile_state, :in_mobile_size, :mobile_location, :mobile_css
      before_validation :normalize_mobile_location
      before_validation :set_mobile_size
      validates :mobile_state, inclusion: { in: %w(disabled enabled) }, if: ->{ mobile_state.present? }
      validates :mobile_size,
        numericality: { only_integer: true, greater_than_or_equal_to: 1_024, less_than_or_equal_to: 1_024_000 },
        if: ->{ mobile_enabled? }
    end

    private
      def normalize_mobile_location
        return if mobile_location.blank?
        self.mobile_location = "/#{mobile_location}" unless mobile_location.start_with?('/')
        self.mobile_location = mobile_location[0, mobile_location.length - 1] if mobile_location.end_with?('/')
      end

      def set_mobile_size
        self.mobile_size = Integer(in_mobile_size) * 1_024 if in_mobile_size.present?
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
        css = css ? "#{self.url}css/mobile.css" : '%{assets_prefix}/cms/mobile.css'
        [css]
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

  end
end
