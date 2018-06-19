# rubocop:disable Metrics/ParameterLists, Metrics/LineLength
module SS::BootstrapSupport::FormOptionsHelper
  extend ActiveSupport::Concern
  include SS::BootstrapSupport::Common

  # see: actionview-4.2.9/lib/action_view/helpers/form_options_helper.rb

  def select(object, method, choices = nil, options = {}, html_options = {}, &block)
    html_options = html_options.with_indifferent_access
    html_options[:class] = bt_sup_merge_css_class(html_options[:class], %w(form-control))
    super(object, method, choices, options, html_options, &block)
  end

  # def collection_select(object, method, collection, value_method, text_method, options = {}, html_options = {})
  #   super
  # end

  # def grouped_collection_select(object, method, collection, group_method, group_label_method, option_key_method, option_value_method, options = {}, html_options = {})
  #   super
  # end

  # def time_zone_select(object, method, priority_zones = nil, options = {}, html_options = {})
  #   super
  # end

  # def options_for_select(container, selected = nil)
  #   super
  # end

  # def options_from_collection_for_select(collection, value_method, text_method, selected = nil)
  #   super
  # end

  # def option_groups_from_collection_for_select(collection, group_method, group_label_method, option_key_method, option_value_method, selected_key = nil)
  #   super
  # end

  # def grouped_options_for_select(grouped_options, selected_key = nil, options = {})
  #   super
  # end

  # def time_zone_options_for_select(selected = nil, priority_zones = nil, model = ::ActiveSupport::TimeZone)
  #   super
  # end

  # def collection_radio_buttons(object, method, collection, value_method, text_method, options = {}, html_options = {}, &block)
  #   super
  # end

  # def collection_check_boxes(object, method, collection, value_method, text_method, options = {}, html_options = {}, &block)
  #   super
  # end
end
# rubocop:enable Metrics/ParameterLists, Metrics/LineLength
