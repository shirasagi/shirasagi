class Gws::Schedule::CommentsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Schedule::Comment

  private

  def set_cur_schedule
    @cur_schedule ||= Gws::Schedule::Plan.find(params[:plan_id])
  end

  def fix_params
    set_cur_schedule
    { cur_site: @cur_site, cur_user: @cur_user, cur_schedule: @cur_schedule }
  end

  public

  def create
    @item = @model.new get_params
    @item.text_type ||= 'plain'
    raise "403" unless @cur_schedule.allowed?(:edit, @cur_user, site: @cur_site)
    # render_create @item.save
    result = @item.save
    if result
      respond_to do |format|
        format.html { redirect_to params[:redirect_to], notice: t('ss.notice.saved') }
        format.json { render json: @item.to_json, status: :created, content_type: json_content_type }
      end
    else
      respond_to do |format|
        format.html { redirect_to params[:redirect_to], notice: @item.errors.full_messages.join("\n") }
        format.json { render json: @item.errors.full_messages, status: :unprocessable_entity, content_type: json_content_type }
      end
    end
  end

  def edit
    raise '403' if @item.user_id != @cur_userlid && !@cur_schedule.allowed?(:edit, @cur_user, site: @cur_site)
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
    raise '403' if @item.user_id != @cur_userlid && !@cur_schedule.allowed?(:edit, @cur_user, site: @cur_site)
    render_update(@item.update, location: params[:redirect_to])
  end

  def delete
    raise '403' if @item.user_id != @cur_userlid && !@cur_schedule.allowed?(:edit, @cur_user, site: @cur_site)
    render
  end

  def destroy
    raise '403' if @item.user_id != @cur_userlid && !@cur_schedule.allowed?(:edit, @cur_user, site: @cur_site)
    render_destroy(@item.destroy, location: params[:redirect_to])
  end
end
