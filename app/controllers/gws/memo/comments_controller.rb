class Gws::Memo::CommentsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Memo::Comment

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
end
