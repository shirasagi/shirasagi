module Opendata::Addon::CommonPageSetting
  extend ActiveSupport::Concern

  included do
    field :show_point, type: String, default: 'show'
    field :show_tabs, type: SS::Extensions::Words
    permit_params :show_point
    permit_params show_tabs: []
    validates :show_point, inclusion: { in: %w(show hide), allow_blank: true }
  end

  def show_point_options
    %w(show hide).map do |v|
      [ I18n.t("views.options.state.#{v}"), v ]
    end
  end

  def hide_point?
    show_point == 'hide'
  end

  def show_point?
    !hide_point?
  end

  def show_tab?(option)
    return true if show_tabs.blank?
    show_tabs.include?(option)
  end
end
