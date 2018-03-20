module Gws::Addon::System::MenuSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    %w(portal reminder schedule todo attendance bookmark memo board faq question report workflow circular monitor share
       shared_address personal_address staff_record links discussion contrast).each do |name|
      define_menu_setting(name)
    end
    define_menu_setting('contrast', default_state: 'hide')
    define_menu_setting('elasticsearch', default_state: 'hide')
  end

  module ClassMethods
    def define_menu_setting(name, options = {})
      field "menu_#{name}_state", type: String, default: options[:default_state]
      field "menu_#{name}_label", type: String, localize: true
      permit_params "menu_#{name}_state", "menu_#{name}_label"
      alias_method("menu_#{name}_state_options", "menu_state_options")

      if !options[:define_visible]
        define_method("menu_#{name}_visible?") do
          menu_visible?(name)
        end
      end
    end
  end

  def menu_state_options
    %w(show hide).map { |k| [I18n.t("ss.options.state.#{k}"), k] }
  end

  def menu_visible?(name)
    name = 'question' if name == 'faq' || name == 'qna'
    try("menu_#{name}_state") != 'hide'
  end
end
