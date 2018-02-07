class Gws::Qna::TopicsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Qna::BaseFilter
  include Gws::Memo::NotificationFilter

  model Gws::Qna::Topic

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

    @items = items.search(params[:s]).
      custom_order(params.dig(:s, :sort) || 'updated_desc').
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

  def resolve
    set_item
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    @item.update_attributes(question_state: 'resolved')
    redirect_to action: :show
  end

  def unresolve
    set_item
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    @item.update_attributes(question_state: 'open')
    redirect_to action: :show
  end
end
