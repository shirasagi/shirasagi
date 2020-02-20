class Gws::Board::CommentsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Board::BaseFilter
  include Gws::Memo::NotificationFilter

  model Gws::Board::Post

  navi_view "gws/board/main/navi"

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, topic_id: params[:topic_id], parent_id: params[:parent_id] }
  end

  def pre_params
    {
      name: "Re: #{@parent.name}",
      group_ids: (@topic.group_ids + @cur_user.group_ids).uniq,
      user_ids: (@topic.user_ids + [ @cur_user.id ]).uniq
    }
  end

  def editable?
    # admin?
    return true if @topic.allowed?(:edit, @cur_user, site: @cur_site, adds_error: false)

    # member?
    if @topic.member?(@cur_user)
      return true if (@item.group_ids & @cur_user.group_ids).present?
      return true if @item.user_ids.include?(@cur_user.id)
    end

    # otherwise
    false
  end

  def deletable?
    # admin?
    return true if @topic.allowed?(:delete, @cur_user, site: @cur_site, adds_error: false)

    # member?
    if @topic.member?(@cur_user)
      return true if (@item.group_ids & @cur_user.group_ids).present?
      return true if @item.user_ids.include?(@cur_user.id)
    end

    # otherwise
    false
  end

  public

  def index
    redirect_to gws_board_topic_path(id: @topic.id)
  end

  def show
    redirect_to gws_board_topic_path(id: @topic.id)
  end

  def new
    @item = @model.new pre_params.merge(fix_params)
    allowed = @item.allowed?(:edit, @cur_user, site: @cur_site, adds_error: false)
    member = @topic.member?(@cur_user)
    raise "403" if !(allowed || member)
  end

  def create
    @item = @model.new get_params
    allowed = @item.allowed?(:edit, @cur_user, site: @cur_site, strict: true, adds_error: false)
    member = @topic.member?(@cur_user)
    if !(allowed || member)
      @item.errors.add(:base, :auth_error)
      return render_create(false)
    end
    render_create @item.save
  end

  def edit
    raise "403" unless editable?

    if @item.is_a?(Cms::Addon::EditLock)
      unless @item.acquire_lock
        redirect_to action: :lock
        return
      end
    end
    render
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    if !editable?
      @item.errors.add(:base, :auth_error)
      return render_update(false)
    end
    render_update @item.save
  end

  def delete
    raise "403" unless deletable?

    render
  end

  def destroy
    raise "403" unless deletable?

    render_destroy @item.destroy
  end
end
