module Gws::Addon::System::MenuSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    define_menu_setting('portal', I18n.t('modules.gws/portal'))
    define_menu_setting('notice', I18n.t('modules.gws/notice'))
    define_menu_setting('reminder', I18n.t('mongoid.models.gws/reminder'))
    define_menu_setting('presence', I18n.t('mongoid.models.gws/presence'))
    define_menu_setting('schedule', I18n.t('modules.gws/schedule'))
    define_menu_setting('todo', I18n.t('modules.gws/schedule/todo'))
    define_menu_setting('affair', I18n.t('modules.gws/affair'))
    define_menu_setting('daily_report', I18n.t('modules.gws/daily_report'))
    define_menu_setting('attendance', I18n.t('modules.gws/attendance'))
    define_menu_setting('bookmark', I18n.t('modules.gws/bookmark'))
    define_menu_setting('memo', I18n.t('modules.gws/memo'))
    define_menu_setting('board', I18n.t('modules.gws/board'))
    define_menu_setting('faq', I18n.t('modules.gws/faq'))
    define_menu_setting('qna', I18n.t('modules.gws/qna'))
    define_menu_setting('workload', I18n.t('modules.gws/workload'))
    define_menu_setting('report', I18n.t('modules.gws/report'))
    define_menu_setting('workflow2', I18n.t('modules.gws/workflow2'))
    define_menu_setting('circular', I18n.t('modules.gws/circular'))
    define_menu_setting('monitor', I18n.t('modules.gws/monitor'))
    define_menu_setting('survey', I18n.t('modules.gws/survey'))
    define_menu_setting('share', I18n.t('modules.gws/share'))
    define_menu_setting('shared_address', I18n.t('modules.gws/shared_address'))
    define_menu_setting('personal_address', I18n.t('modules.gws/personal_address'))
    define_menu_setting('staff_record', I18n.t('gws/staff_record.staff_records'))
    define_menu_setting('links', I18n.t('mongoid.models.gws/link'))
    define_menu_setting('discussion', I18n.t('modules.gws/discussion'))
    define_menu_setting('tabular', I18n.t('modules.gws/tabular'))
    define_menu_setting('contrast', I18n.t('mongoid.models.gws/contrast'), default_state: 'hide')
    define_menu_setting('elasticsearch', I18n.t('modules.gws/elasticsearch'), default_state: 'hide')
    define_menu_setting('workflow', I18n.t('modules.gws/workflow'), default_state: 'hide')
    define_menu_setting('conf', I18n.t('gws.site_config'))
  end

  module ClassMethods
    def define_menu_setting(name, default_label, options = {})
      field "menu_#{name}_state", type: String, default: options[:default_state]
      field "menu_#{name}_label", type: String, localize: true
      belongs_to_file "menu_#{name}_icon_image", class_name: "SS::File", accepts: SS::File::IMAGE_FILE_EXTENSIONS + [".svg"]
      permit_params "menu_#{name}_state", "menu_#{name}_label", "menu_#{name}_icon_image_id"
      alias_method("menu_#{name}_state_options", "menu_state_options")

      define_method("menu_#{name}_default_label") do
        default_label
      end
      define_method("menu_#{name}_effective_label") do
        send("menu_#{name}_label").presence || send("menu_#{name}_default_label")
      end
      define_method("menu_#{name}_visible?") do
        menu_visible?(name)
      end
    end
  end

  def menu_state_options
    %w(show hide).map { |k| [I18n.t("ss.options.state.#{k}"), k] }
  end

  def menu_visible?(name)
    try("menu_#{name}_state") != 'hide'
  end
end
