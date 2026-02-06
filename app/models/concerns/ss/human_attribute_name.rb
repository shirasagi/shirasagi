module SS::HumanAttributeName
  extend ActiveSupport::Concern

  included do
    delegate :t, :tt, to: :class
  end

  module ClassMethods
    def t(*args)
      human_attribute_name(*args)
    end

    def tt(key)
      model_names = ancestors.select { |x| x.respond_to?(:model_name) }
      msg = ""
      model_names.each do |model_name|
        msg = I18n.t("tooltip.#{model_name.model_name.i18n_key}.#{key}", default: "")
        break if msg.present?
      end
      return msg if msg.blank?

      list = Array(msg)
        .map { _1.to_s.gsub(/\r\n|\n/, "<br />") }
        .map { "<li>#{_1}<br /></li>" }

      <<~HTML.html_safe
        <div class="tooltip">?
          <ul class="tooltip-content">
            #{list.join("\n")}
          </ul>
        </div>
      HTML
    end
  end
end
