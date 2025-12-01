class Sys::Diag::MailsController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  navi_view "sys/diag/main/navi"
  menu_view nil

  class MailDiagParam
    include ActiveModel::Model
    include ActiveModel::Attributes

    attr_accessor :cur_user

    attribute :from_type, :string
    attribute :from_site, :string
    attribute :from_manual, :string
    attribute :to, :string
    attribute :cc, :string
    attribute :bcc, :string
    attribute :subject, :string
    attribute :body, :string

    class << self
      def new_default(cur_user:)
        new(
          cur_user: cur_user,
          from_type: "site",
          to: cur_user.email,
          subject: "TEST MAIL",
          body: "Message\nMessage\nMessage"
        )
      end
    end

    def from
      return from_manual if from_type == "manual"
      return if from_site.blank?

      type, id = from_site.split(":", 2)
      return if type.blank? || id.blank? || !id.numeric?

      id = id.to_i
      case type
      when "cms"
        SS.cms_sites(cur_user).find { _1.id == id }.sender_address
      when "gws"
        SS.gws_sites(cur_user).find { _1.id == id }.sender_address
      else
        nil
      end
    end
  end

  private

  def set_crumbs
    @crumbs << ["MAIL Test", action: :index]
  end

  def permit_fields
    [:from_type, :from_site, :from_manual, :to, :cc, :bcc, :subject, :body]
  end

  public

  def index
    raise "403" unless SS::User.allowed?(:edit, @cur_user)
    @item = MailDiagParam.new_default(cur_user: @cur_user)
  end

  def create
    raise "403" unless SS::User.allowed?(:edit, @cur_user)

    @item = MailDiagParam.new(cur_user: @cur_user)
    @item.attributes = get_params

    if @item.valid?
      Sys::Mailer.test_mail(
        from: @item.from,
        to: @item.to,
        cc: @item.cc,
        bcc: @item.bcc,
        subject: @item.subject,
        body: @item.body
      ).deliver_now
    end

    redirect_to({ action: :index }, { notice: "Sent Successfully" })
  end
end
