class Cms::MembersController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Member

  navi_view "cms/cms/navi"

  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :verify]

  private

  def set_crumbs
    @crumbs << [t("cms.member"), action: :index]
  end

  def fix_params
    { cur_site: @cur_site }
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

    @items = @model.site(@cur_site).
      allow(:edit, @cur_user, site: @cur_site).
      search(params[:s]).
      order_by(name: 1, id: 1).
      page(params[:page]).per(50)
  end

  def download
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

    csv = @model.site(@cur_site).
      allow(:edit, @cur_user, site: @cur_site).
      search(params[:s]).
      order_by(id: 1).
      to_csv
    send_data csv.encode("SJIS", invalid: :replace, undef: :replace), filename: "members_#{Time.zone.now.to_i}.csv"
  end

  def verify
    raise '404' unless @node = Member::Node::Registration.first
    return if request.get?

    Member::Mailer.verification_mail(@item).deliver_now
    @item.verify_mail_sent = Time.zone.now.to_i
    render_update @item.update, notice: I18n.t('ss.notice.sent')
  end
end
