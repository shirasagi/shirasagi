module Gws::Memo::MessageHelper
  module Fomatter
    module_function

    SINGLE_KEYS = %i[unseen flagged].freeze

    def format_key_value(params, key)
      return unless params.key?(key)

      if SINGLE_KEYS.include?(key)
        Gws::Memo::Message.t(key)
      else
        val = params[key]
        val.present? ? "#{Gws::Memo::Message.t(key)}: #{val}" : nil
      end
    end

    def format_text(params, key)
      return unless params.key?(key)

      val = params[key]
      return if val.blank?

      "#{I18n.t 'gws/memo/message.message'}: #{val}"
    end

    def format_send_date(params, _key)
      since = params[:since]
      before = params[:before]
      return if since.blank? && before.blank?

      val = [ since.presence, before.presence ].join(" - ")
      "#{Gws::Memo::Message.t(:send_date)}: #{val}"
    end

    def format_priorities(params, _key)
      priorities = params[:priorities]
      return if priorities.blank?

      priorities = priorities.compact.select(&:present?)
      return if priorities.blank?

      priorities.map! { |v| I18n.t("gws/memo.options.priority.#{v}", default: nil) }.compact
      return if priorities.blank?

      "#{Gws::Memo::Message.t(:priority)}: #{priorities.join(", ")}"
    end
  end

  SEARCH_KEYS = %i[from_member_name to_member_name subject text send_date unseen flagged priorities].freeze

  def searched_label(params)
    return nil if params.blank?

    h = []
    SEARCH_KEYS.each do |key|
      if Fomatter.respond_to?("format_#{key}")
        h << Fomatter.send("format_#{key}", params, key)
      else
        h << Fomatter.format_key_value(params, key)
      end
    end

    h.compact.join(", ")
  end
end