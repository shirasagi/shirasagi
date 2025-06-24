module Gws::Addon::System::MenuSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    %w(portal notice reminder presence schedule todo affair daily_report attendance bookmark memo board
       faq qna workload report workflow2 circular monitor survey share shared_address personal_address
       staff_record links discussion).each do |name|
      define_menu_setting(name)
    end
    define_menu_setting('contrast', default_state: 'hide')
    define_menu_setting('elasticsearch', default_state: 'hide')
    define_menu_setting('workflow', default_state: 'hide')
    define_menu_setting('affair', default_state: 'hide')
    define_menu_setting('conf')
  end

  module ClassMethods
    def define_menu_setting(name, options = {})
      field "menu_#{name}_state", type: String, default: options[:default_state]
      field "menu_#{name}_label", type: String, localize: true
      field "menu_#{name}_icon_image_id", type: BSON::ObjectId
      belongs_to "menu_#{name}_icon_image", class_name: "SS::File", optional: true
      permit_params "menu_#{name}_state", "menu_#{name}_label", "menu_#{name}_icon_image_id"
      alias_method("menu_#{name}_state_options", "menu_state_options")

      before_save :set_menu_icon_owner

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
    try("menu_#{name}_state") != 'hide'
  end

  def set_menu_icon_owner
    %w(portal notice reminder presence schedule todo affair affair2 daily_report attendance bookmark memo board
       faq qna workload report workflow2 circular monitor survey share shared_address personal_address
       discussion contrast elasticsearch workflow conf).each do |name|
      icon_file = send("menu_#{name}_icon_image")
      next unless icon_file

      if icon_file.owner_item != self || icon_file.state != "public"
        icon_file.owner_item = self
        icon_file.state = "public"
        icon_file.site_id = icon_file.owner_item_id
        icon_file.save!
      end
      Rails.logger.debug "[set_menu_icon_owner] icon_file: #{icon_file.inspect}"
    end
  end
end
