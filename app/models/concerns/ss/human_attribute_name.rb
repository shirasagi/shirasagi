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
      model_names = ancestors.filter_map { _1.try(:model_name) }
      scope = model_names.map { "tooltip.#{_1.i18n_key}" }
      SS::HumanAttributeName.tt(key, scope: scope)
    end
  end

  def self.find_tt(key, scope: nil, **opts)
    msg = nil

    if scope
      Array(scope).flatten.each do |scope1|
        msg = I18n.t(key, **opts.merge(default: '', scope: scope1))
        break if msg.present?
      end
    end

    msg = I18n.t(key, **opts.merge(default: '', scope: 'tooltip')) if msg.blank?
    msg
  end

  def self.tt(key, scope: nil, symbol: nil, html_wrap: true, **opts)
    msg = self.find_tt(key, scope: scope, **opts)
    return msg if msg.blank? || !html_wrap

    list = Array(msg)
      .map { _1.to_s.gsub(/\r\n|\n/, "<br />") }
      .map { "<li>#{_1}<br /></li>" }

    <<~HTML.html_safe
      <div class="tooltip">#{symbol || "?"}
        <ul class="tooltip-content">
          #{list.join("\n")}
        </ul>
      </div>
    HTML
  end
end
