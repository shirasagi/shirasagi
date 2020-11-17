class Sys::Diag::MailsController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  navi_view "sys/diag/main/navi"
  menu_view nil

  private

  def set_crumbs
    @crumbs << ["MAIL Test", action: :index]
  end

  def permit_fields
    [:from, :to, :subject, :body]
  end

  public

  def index
    raise "403" unless SS::User.allowed?(:edit, @cur_user)

    @item = OpenStruct.new(
      from: @cur_user.email,
      to: @cur_user.email,
      subject: "TEST MAIL",
      body: "Message\nMessage\nMessage"
    )
  end

  def create
    @item = OpenStruct.new from: "", to: "", subject: "", body: ""

    prm = get_params
    @item.from    = prm[:from]
    @item.to      = prm[:to]
    @item.subject = prm[:subject]
    @item.body    = prm[:body]

    if @item.to.present? && @item.subject.present? && @item.body.present?
      Sys::Mailer.test_mail(
        from: @item.from,
        to: @item.to,
        subject: @item.subject,
        body: @item.body
      ).deliver_now
    end

    redirect_to({ action: :index }, { notice: "Sent Successfully" })
  end
end
