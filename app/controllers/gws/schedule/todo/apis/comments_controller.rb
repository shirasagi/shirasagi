class Gws::Schedule::Todo::Apis::CommentsController < ApplicationController
  include Gws::ApiFilter
  include Gws::Memo::NotificationFilter

  model Gws::Schedule::TodoComment

  private

  def set_discussion_forum
    if params[:forum_id].present?
      @cur_discussion_forum ||= Gws::Discussion::Forum.site(@cur_site).find(params[:forum_id])
    end
  end

  def set_cur_todo
    @cur_todo ||= begin
      set_discussion_forum
      criteria = Gws::Schedule::Todo.site(@cur_site)
      criteria = criteria.discussion_forum(@cur_discussion_forum) if @cur_discussion_forum
      todo = criteria.find(params[:todo_id])
      if @cur_discussion_forum
        todo.in_discussion_forum = true
        todo.discussion_forum = @cur_discussion_forum
      end
      todo
    end
  end

  def fix_params
    set_cur_todo
    { cur_site: @cur_site, cur_user: @cur_user, cur_todo: @cur_todo, todo: @cur_todo }
  end

  def set_item
    set_cur_todo
    @item ||= begin
      item = @cur_todo.comments.find(params[:id])
      item.attributes = fix_params
      item
    end
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  def last_achievement_rate
    criteria = @cur_todo.comments.exists(achievement_rate: true)
    last_comment = criteria.order_by(created: -1).first
    return if last_comment.blank?

    last_comment.achievement_rate
  end

  public

  def create
    @item = @model.new get_params
    @item.text_type ||= 'plain'
    if !@cur_todo.member?(@cur_user) && !@cur_todo.allowed?(:edit, @cur_user, site: @cur_site)
      raise "403"
    end
    @cur_todo.errors.clear

    result = @item.save
    if result
      @cur_todo.update(achievement_rate: @item.achievement_rate) if @item.achievement_rate.present?

      respond_to do |format|
        format.html { redirect_to URI.parse(params[:redirect_to].to_s).path, notice: t('ss.notice.saved') }
        format.json { render json: @item.to_json, status: :created, content_type: json_content_type }
      end
    else
      respond_to do |format|
        format.html { redirect_to URI.parse(params[:redirect_to].to_s).path, notice: @item.errors.full_messages.join("\n") }
        format.json { render json: @item.errors.full_messages, status: :unprocessable_entity, content_type: json_content_type }
      end
    end
  end

  def edit
    raise '403' if @item.user_id != @cur_user.id && !@cur_todo.allowed?(:edit, @cur_user, site: @cur_site)
    @cur_todo.errors.clear

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
    raise '403' if @item.user_id != @cur_user.id && !@cur_todo.allowed?(:edit, @cur_user, site: @cur_site)
    @cur_todo.errors.clear

    result = @item.save
    if result
      @cur_todo.update(achievement_rate: last_achievement_rate || 0)
    end

    render_update(result, location: params[:redirect_to])
  end

  def delete
    raise '403' if @item.user_id != @cur_user.id && !@cur_todo.allowed?(:edit, @cur_user, site: @cur_site)
    @cur_todo.errors.clear

    render
  end

  def destroy
    raise '403' if @item.user_id != @cur_user.id && !@cur_todo.allowed?(:edit, @cur_user, site: @cur_site)
    @cur_todo.errors.clear

    result = @item.destroy
    if result
      @cur_todo.update(achievement_rate: last_achievement_rate || 0)
    end
    render_destroy(result, location: params[:redirect_to])
  end
end
