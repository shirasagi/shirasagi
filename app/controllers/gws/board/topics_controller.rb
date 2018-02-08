class Gws::Board::TopicsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Board::BaseFilter
  include Gws::Memo::NotificationFilter

  model Gws::Board::Topic

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def pre_params
    p = super
    p[:category_ids] = [@category.id] if @category.present?
    p
  end

  def items
    if @mode == 'editable'
      @model.site(@cur_site).topic.allow(:read, @cur_user, site: @cur_site)
    else
      @model.site(@cur_site).topic.and_public.readable(@cur_user, site: @cur_site)
    end
  end

  def readable?
    if @mode == 'editable'
      @item.allowed?(:read, @cur_user, site: @cur_site)
    else
      @item.readable?(@cur_user)
    end
  end

  public

  def index
    if @category.present?
      params[:s] ||= {}
      params[:s][:site] = @cur_site
      params[:s][:category] = @category.name
    end

    if params[:s]
      params[:s][:user] = @cur_user
    end

    @items = items.search(params[:s]).
      order(descendants_updated: -1).
      page(params[:page]).per(50)
  end

  def show
    raise '403' unless readable?
    render file: "show_#{@item.mode}"
  end

  def read
    set_item
    raise '403' unless readable?

    result = true
    if !@item.browsed?(@cur_user)
      @item.set_browsed(@cur_user)
      @item.record_timestamps = false
      result = @item.save
    end

    if result
      respond_to do |format|
        format.html { redirect_to({ action: :show }, { notice: t('ss.notice.saved') }) }
        format.json { render json: { _id: @item.id, browsed_at: @item.browsed_at(@cur_user) }, content_type: json_content_type }
      end
    else
      respond_to do |format|
        format.html { render({ file: :edit }) }
        format.json { render(json: @item.errors.full_messages, status: :unprocessable_entity, content_type: json_content_type) }
      end
    end
  end

  def print
    set_item
    render file: "print_#{@item.mode}", layout: 'ss/print'
  end
end
