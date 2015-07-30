module SS::TransSidFilter
  extend ActiveSupport::Concern

  included do
    if defined?(Jpmobile)
      before_action :set_trans_sid
      trans_sid :none
    end
  end

  private
    def mobile_path?
      filters = request.env["ss.filters"]
      return false if filters.blank?
      filters.include?(:mobile)
    end

    def set_trans_sid
      case SS.config.mobile.trans_sid.to_sym
      when :always
        self.trans_sid_mode = :always
      when :mobile
        if mobile_path?
          self.trans_sid_mode = :mobile
        end
      end
    end
end
