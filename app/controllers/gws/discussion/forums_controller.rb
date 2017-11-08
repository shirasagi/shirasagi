class Gws::Discussion::ForumsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Discussion::Forum

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_crumbs
    @crumbs << [I18n.t('modules.gws/discussion'), gws_discussion_forums_path]
  end

  public

  def index
    @items = @model.site(@cur_site).topic

    if params[:s] && params[:s][:state] == "closed"
      @items = @items.and_closed.allow(:read, @cur_user, site: @cur_site)
    else
      @items = @items.and_public.readable(@cur_user, @cur_site, include_role: true)
    end

    @items.search(params[:s]).
      page(params[:page]).per(50)
  end

  def create
    @item = @model.new get_params
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    result = @item.save
    @item.save_main_topic if result
    render_create result
  end

  def copy
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)

    set_item
    if request.get?
      prefix = I18n.t("workflow.cloned_name_prefix")
      @item.name = "[#{prefix}] #{@item.name}"
      return
    end

    @item.attributes = get_params
    if @item.valid?
      item = @item.save_clone
      item.attributes = get_params
      render_create true, render: { file: :copy }
    else
      render_create false, render: { file: :copy }
    end
  end
end
