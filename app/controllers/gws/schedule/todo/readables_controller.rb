class Gws::Schedule::Todo::ReadablesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::TodoFilter
  include Gws::Schedule::Todo::NotificationFilter

  self.default_todo_state = "except_finished"

  private

  def set_crumbs
    set_category

    @crumbs << [@cur_site.menu_todo_label || t('modules.addons.gws/schedule/todo'), gws_schedule_todo_main_path]
    @crumbs << [t('gws/schedule.tabs.my_todo'), { category: Gws::Schedule::TodoCategory::ALL.id }]
    if @cur_category
      @crumbs << [@cur_category.name, { category: @cur_category }]
    end
  end

  def set_items
    @items ||= @model.site(@cur_site).
      member(@cur_user).
      without_deleted.
      search(@s).
      custom_order(params.dig(:s, :sort) || 'end_at_asc')
  end
end
