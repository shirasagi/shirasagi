class Cms::Apis::Line::DeliverMembersController < ApplicationController
  include Cms::ApiFilter

  model Cms::Line::Message

  def set_model
    case params[:model]
    when "message"
      @model = Cms::Line::Message
    when "deliver_condition"
      @model = Cms::Line::DeliverCondition
    when "line_deliver"
      @model = Cms::SnsPostLog::LineDeliver
    else
      raise "404"
    end
  end

  def set_items
    @message = @model.site(@cur_site).find(params[:id])
    @items = @message.extract_deliver_members
  end

  def index
    set_items
    @items = @items.search(params[:s]).page(params[:page]).per(50)
  end

  def download
    set_items
    send_enum @items.line_members_enum(@cur_site), type: 'text/csv; charset=Shift_JIS',
      filename: "members_#{Time.zone.now.strftime("%Y%m%d_%H%M")}.csv"
  end
end
