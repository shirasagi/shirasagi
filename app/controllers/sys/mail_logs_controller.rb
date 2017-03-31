require 'nkf'

class Sys::MailLogsController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  model Sys::MailLog
  menu_view "sys/crud/menu"

  def index
    raise "403" unless SS::User.allowed?(:read, @cur_user)

    @items = @model.
      search(params[:s]).
      order_by(id: -1).
      page(params[:page]).per(50)
  end

  def show
    raise "403" unless SS::User.allowed?(:read, @cur_user)
  end

  def delete
    raise "403" unless SS::User.allowed?(:delete, @cur_user)
    render
  end

  def destroy
    raise "403" unless SS::User.allowed?(:delete, @cur_user)
    render_destroy @item.destroy
  end

  def decode
    set_item

    if @item.subject =~ /ISO-2022-JP/i
      @item.subject = NKF.nkf("-w", @item.subject)
    end

    if @item.mail =~ /ISO-2022-JP/i
      @item.mail = NKF.nkf("-w", @item.mail)
    end
  end

  def commit_decode
    raise "403" unless SS::User.allowed?(:edit, @cur_user)
    set_item
    @item.set(params.require(:item).permit(:subject, :mail))
    render_update true
  end

  private
    def set_crumbs
      @crumbs << [ @model.model_name.human, action: :index ]
    end
end
