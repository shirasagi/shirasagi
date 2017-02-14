class Webmail::MailsController < ApplicationController
  include Webmail::BaseFilter
  include Webmail::ImapFilter
  include Sns::CrudFilter

  model Webmail::Mail

  skip_before_action :set_selected_items
  before_action :apply_filters, if: ->{ request.get? }
  before_action :set_mailbox
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy]
  before_action :set_view_name, only: [:new, :create, :edit, :update]

  private
    def set_crumbs
      @crumbs << [:'webmail.mail', { action: :index } ]
    end

    def apply_filters
      count = Webmail::Filter.user(@cur_user).enabled.apply_all 'INBOX', ['NEW']
      flash[:notice] = t('webmail.notice.filter_applied', count: count) if count > 0
    end

    def set_mailbox
      @navi_mailboxes = true
      @imap.examine(@mailbox = params[:mailbox])
    end

    def fix_params
      @imap.account_attributes.merge(cur_user: @cur_user, sync: true, mailbox: @mailbox)
    end

    def set_item
      @item = @model.where(mailbox: @mailbox).imap_find params[:id], :body
      @item.attributes = fix_params
    end

    def set_view_name
      @addon_basic_name = @model.t :to
    end

    def crud_redirect_url
      { action: :index }
    end

    def get_uids
      ids = params[:ids].presence || [params[:id]]
      ids.map(&:to_i)
    end

  public
    def index
      @items = @model.
        where(mailbox: @mailbox).
        imap_search(params[:s]).
        page(params[:page]).
        per(50).
        imap_all
    end

    def show
      @item.set_seen if @item.unseen?
    end

    def header_view
      @item = @model.where(mailbox: @mailbox).imap_find params[:id]
      render plain: @item.header, layout: false
    end

    def source_view
      @item = @model.where(mailbox: @mailbox).imap_find params[:id], :rfc822
      render plain: @item.rfc822, layout: false
    end

    def download
      @item = @model.where(mailbox: @mailbox).imap_find params[:id], :rfc822

      send_data @item.rfc822, filename: "#{@item.subject}.eml",
                content_type: 'message/rfc822', disposition: :attachment
    end

    def parts
      part = @model.where(mailbox: @mailbox).find_part params[:id], params[:section]
      disposition = part.image? ? :inline : :attachment

      send_data part.decoded, filename: part.filename,
                content_type: part.content_type, disposition: disposition
    end

    def new
      @item = @model.new pre_params.merge(fix_params)
      @item.new_mail
    end

    def reply
      @ref  = @model.where(mailbox: @mailbox).imap_find params[:id], :body
      @item = @model.new pre_params.merge(fix_params)
      @item.new_reply(@ref)
      render :new
    end

    def reply_all
      @ref  = @model.where(mailbox: @mailbox).imap_find params[:id], :body
      @item = @model.new pre_params.merge(fix_params)
      @item.new_reply_all(@ref)
      render :new
    end

    def forward
      @ref  = @model.where(mailbox: @mailbox).imap_find params[:id], :body
      @item = @model.new pre_params.merge(fix_params)
      @item.new_forward(@ref)
      render :new
    end

    def create
      @item = @model.new
      @item.attributes = get_params

      if params[:commit] == I18n.t('views.button.draft_save')
        notice = nil
        resp = @item.save_draft
      else
        notice = t('views.notice.sent')
        resp = @item.send_mail
      end

      @item.destroy_files
      render_create resp, notice: notice
    end

    def destroy
      raise "403" unless @item.allowed?(:delete, @cur_user)
      render_destroy @item.move_trash
    end

    def set_seen
      @model.set_seen get_uids
      render_change :set_seen
    end

    def unset_seen
      @model.unset_seen get_uids
      render_change :unset_seen
    end

    def set_star
      @model.set_star get_uids
      render_change :set_star, redirect: { action: :show }
    end

    def unset_star
      @model.unset_star get_uids
      render_change :unset_star, redirect: { action: :show }
    end

    def destroy_all
      @model.uids_move_trash get_uids
      render_change :delete
    end

    def copy
      @model.uids_copy get_uids, params[:dst]
      render_change :copy
    end

    def move
      @model.uids_move get_uids, params[:dst]
      render_change :move
    end

    def render_change(action, opts = {})
      location = params[:redirect].presence || opts[:redirect] || { action: :index }

      respond_to do |format|
        format.html { redirect_to location, notice: t("webmail.notice.#{action}") }
        format.json { head :no_content }
      end
    end
end
