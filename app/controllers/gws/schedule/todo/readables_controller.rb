class Gws::Schedule::Todo::ReadablesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::TodoFilter

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_schedule_label || t('modules.gws/schedule'), gws_schedule_main_path]
    @crumbs << [t('modules.addons.gws/schedule/todo'), gws_schedule_todo_readables_path]
  end

  def set_items
    @items ||= @model.site(@cur_site).
      member_or_readable(@cur_user, site: @cur_site, include_role: true).
      without_deleted.
      search(params[:s]).
      custom_order(params.dig(:s, :sort) || 'end_at_asc')
  end
end
