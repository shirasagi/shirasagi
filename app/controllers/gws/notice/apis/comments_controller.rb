class Gws::Notice::Apis::CommentsController < ApplicationController
  include Gws::ApiFilter

  model Gws::Notice::Comment

  private

  def set_cur_notice
    @cur_notice ||= Gws::Notice::Post.site(@cur_site).find(params[:notice_id])
  end

  def fix_params
    set_cur_notice
    { cur_site: @cur_site, cur_user: @cur_user, cur_notice: @cur_notice }
  end

  def set_item
    set_cur_notice
    @item ||= begin
      item = @cur_notice.comments.find(params[:id])
      item.attributes = fix_params
      item
    end
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  public

  def create
    @item = @model.new get_params
    @item.text_type ||= 'plain'
    if !@cur_notice.readable?(@cur_user, site: @cur_site) && !@cur_notice.allowed?(:edit, @cur_user, site: @cur_site)
      raise "403"
    end
    result = @item.save
    if result
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
    raise '403' if @item.user_id != @cur_user.id && !@cur_notice.allowed?(:edit, @cur_user, site: @cur_site)
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
    raise '403' if @item.user_id != @cur_user.id && !@cur_notice.allowed?(:edit, @cur_user, site: @cur_site)
    render_update(@item.update, location: params[:redirect_to])
  end

  def delete
    raise '403' if @item.user_id != @cur_user.id && !@cur_notice.allowed?(:edit, @cur_user, site: @cur_site)
    render
  end

  def destroy
    raise '403' if @item.user_id != @cur_user.id && !@cur_notice.allowed?(:edit, @cur_user, site: @cur_site)
    render_destroy(@item.destroy, location: params[:redirect_to])
  end
end
