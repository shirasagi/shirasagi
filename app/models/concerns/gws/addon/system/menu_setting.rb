module Gws::Addon::System::MenuSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    define_menu_setting('portal', 'modules.gws/portal')
    define_menu_setting('notice', 'modules.gws/notice')
    define_menu_setting('reminder', 'mongoid.models.gws/reminder')
    define_menu_setting('presence', 'mongoid.models.gws/presence')
    define_menu_setting('schedule', 'modules.gws/schedule')
    define_menu_setting('todo', 'modules.gws/schedule/todo')
    define_menu_setting('affair', 'modules.gws/affair')
    define_menu_setting('daily_report', 'modules.gws/daily_report')
    define_menu_setting('attendance', 'modules.gws/attendance')
    define_menu_setting('bookmark', 'modules.gws/bookmark')
    define_menu_setting('memo', 'modules.gws/memo')
    define_menu_setting('board','modules.gws/board')
    define_menu_setting('faq', 'modules.gws/faq')
    define_menu_setting('qna', 'modules.gws/qna')
    define_menu_setting('workload', 'modules.gws/workload')
    define_menu_setting('report', 'modules.gws/report')
    define_menu_setting('workflow2', 'modules.gws/workflow2')
    define_menu_setting('circular', 'modules.gws/circular')
    define_menu_setting('monitor', 'modules.gws/monitor')
    define_menu_setting('survey', 'modules.gws/survey')
    define_menu_setting('share', 'modules.gws/share')
    define_menu_setting('shared_address', 'modules.gws/shared_address')
    define_menu_setting('personal_address', 'modules.gws/personal_address')
    define_menu_setting('staff_record', 'gws/staff_record.staff_records')
    define_menu_setting('links', 'mongoid.models.gws/link')
    define_menu_setting('discussion', 'modules.gws/discussion')
    define_menu_setting('tabular', 'modules.gws/tabular')
    define_menu_setting('contrast', 'mongoid.models.gws/contrast', default_state: 'hide')
    define_menu_setting('elasticsearch', 'modules.gws/elasticsearch', default_state: 'hide')
    define_menu_setting('workflow', 'modules.gws/workflow', default_state: 'hide')
    define_menu_setting('conf', 'gws.site_config')
  end

  module ClassMethods
    def define_menu_setting(name, i18n_key, options = {})
      field "menu_#{name}_state", type: String, default: options[:default_state]
      field "menu_#{name}_label", type: String, localize: true
      belongs_to_file "menu_#{name}_icon_image", class_name: "SS::File", accepts: SS::File::IMAGE_FILE_EXTENSIONS + [".svg"]
      permit_params "menu_#{name}_state", "menu_#{name}_label", "menu_#{name}_icon_image_id"
      alias_method("menu_#{name}_state_options", "menu_state_options")

      define_method("menu_#{name}_default_label") do
        I18n.t(i18n_key)
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
