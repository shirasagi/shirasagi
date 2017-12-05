class Gws::Memo::CommentsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Memo::Comment

  before_action :set_item, only: [:destroy]

  def set_cur_message
    @cur_message ||= Gws::Memo::Message.find(params[:message_id])
  end

  def fix_params
    set_cur_message
    { cur_site: @cur_site, cur_user: @cur_user, cur_message: @cur_message, text_type: 'plain' }
  end

  def create
    @item = @model.new get_params
    result = @item.save
    if result
      respond_to do |format|
        format.html { redirect_to params[:redirect_to], notice: t('ss.notice.saved') }
        format.json { render json: @item.to_json, status: :created, content_type: json_content_type }
      end
    else
      respond_to do |format|
        format.html { redirect_to params[:redirect_to], notice: @item.errors.full_messages.join('\n') }
        format.json { render json: @item.errors.full_messages, status: :unprocessable_entity, content_type: json_content_type }
      end
    end
  end

  def destroy
    result = @item.user.id == @cur_user.id ? @item.destroy : false
    if result
      respond_to do |format|
        format.html { redirect_to params[:redirect_to], notice: t('ss.notice.deleted') }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to params[:redirect_to], notice: t('modules.errors.other_user_comment_deletion') }
        format.json { render json: t('modules.errors.other_user_comment_deletion'), status: :unprocessable_entity }
      end
    end
  end
end
