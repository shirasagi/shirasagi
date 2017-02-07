class Webmail::MailsController < ApplicationController
  include Webmail::BaseFilter
  include Webmail::ImapFilter
  include Sns::CrudFilter

  model Webmail::Mail

  skip_before_action :set_selected_items
  before_action :apply_filters, if: ->{ request.get? }
  before_action :set_mailbox
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy]

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

      if params[:reply]
        @item.new_reply params[:reply]
      elsif params[:reply_all]
        @item.new_reply_all params[:reply_all]
      elsif params[:forward]
        @item.new_forward params[:forward]
      else
        @item.new_create
      end

      raise "403" unless @item.allowed?(:edit, @cur_user)
    end

    def create
      @item = @model.new
      @item.mail_attributes = get_params

      msg = Webmail::Mailer.new_message(@item)

      if params[:commit] == I18n.t("views.button.save")
        @item.save_to_draft(msg.to_s)
      else
        @item.save_to_sent(msg.deliver_now.to_s)
      end

      @item.destroy_files

      render_create true
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
