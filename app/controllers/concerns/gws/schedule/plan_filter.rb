module Gws::Schedule::PlanFilter
  extend ActiveSupport::Concern

  included do
    prepend_view_path "app/views/gws/schedule/plans"
    menu_view "gws/schedule/main/menu"
    helper Gws::Schedule::PlanHelper
    model Gws::Schedule::Plan
  end

  private
    def set_crumbs
      @crumbs << [:"modules.gws/schedule", gws_schedule_plans_path]
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end

    def pre_params
      @skip_default_group = true
      {
        start_at: params[:start] || Time.zone.now.strftime('%Y/%m/%d %H:00'),
        member_ids: params[:member_ids].presence || [@cur_user.id],
        facility_ids: params[:facility_ids].presence
      }
    end

    def redirection_view
      'agendaDay'
    end

    def redirection_url
      url_for(action: :index) + "?calendar[view]=#{redirection_view}&calendar[date]=#{@item.start_at.to_date}"
    end

  public
    def index
      render
    end

    def show
      raise '403' unless @item.readable?(@cur_user)
      render
    end

    def events
      @items = []
    end

    def popup
      set_item

      if @item.readable?(@cur_user)
        render file: "popup", layout: false
      else
        render file: "popup_hidden", layout: false
      end
    end

    def create
      @item = @model.new get_params
      raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

      render_create @item.save, location: redirection_url
    end

    def update
      @item.attributes = get_params
      @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
      raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

      render_update @item.update, location: redirection_url
    end

    def destroy
      raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)
      @item.edit_range = params.dig(:item, :edit_range)
      render_destroy @item.destroy
    end
end
