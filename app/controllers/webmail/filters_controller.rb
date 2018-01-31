class Webmail::FiltersController < ApplicationController
  include Webmail::BaseFilter
  include Sns::CrudFilter

  model Webmail::Filter

  before_action :imap_login, except: [:index]

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.webmail/filter"), { action: :index } ]
    @webmail_other_account_path = :webmail_filters_path
  end

  def fix_params
    @imap.account_scope.merge(cur_user: @cur_user, imap: @imap)
  end

  public

  def index
    @items = @model.
      user(@cur_user).
      imap_setting(@cur_user, @imap_setting).
      search(params[:s]).
      page(params[:page]).
      per(50)
  end

  def apply
    set_item

    mailbox = params[:mailbox].presence
    return render(file: :show) if mailbox.blank?

    count = @item.apply(mailbox)
    return render(file: :show) if count == false

    @imap.mailboxes.update_status

    respond_to do |format|
      format.html { redirect_to(action: :show, notice: t('webmail.notice.multiple.filtered', count: count)) }
      format.json { head :no_content }
    end
  end
end
