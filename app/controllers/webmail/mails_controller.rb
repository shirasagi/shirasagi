class Webmail::MailsController < ApplicationController
  include Webmail::BaseFilter
  include Webmail::ImapFilter
  include Sns::CrudFilter

  model Webmail::Mail

  skip_action_callback :set_destroy_items
  before_action :apply_filters, if: ->{ request.get? }
  before_action :set_mailbox
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy,
                                  :attachment, :download, :header_view, :source_view]

  private
    def set_crumbs
      @crumbs << [:'webmail.mail', { action: :index } ]
    end

    def apply_filters
      count = Webmail::Filter.user(@cur_user).enabled.apply_all 'INBOX', ['NEW']
      flash[:notice] = t('webmail.notice.filter_applied', count: count) if count > 0
    end

    def set_mailbox
      @mailbox = params[:mailbox]
      @navi_mailboxes = true
      @imap.examine(@mailbox)
    end

    def fix_params
      @imap.cache_key.merge(cur_user: @cur_user, sync: true, mailbox: @mailbox)
    end

    def set_item
      set_mailbox
      @item = @model.where(mailbox: @mailbox).imap_find params[:id]
      @item.attributes = fix_params
    end

    def crud_redirect_url
      { action: :index }
    end

    def get_uids
      params[:ids].presence || [params[:id]]
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

    def attachment
      @item.attachments.each_with_index do |at, idx|
        next unless idx == params[:idx].to_i

        disposition = at.content_type.start_with?('image') ? :inline : :attachment
        return send_data at.read, filename: at.filename, content_type: at.content_type, disposition: disposition
      end

      raise '404'
    end

    def download
      data = @item.rfc822
      name = @item.subject + '.eml'
      send_data data, filename: name, content_type: 'message/rfc822', disposition: :attachment
    end

    def header_view
      data = @item.rfc822.sub(/(\r\n|\n){2}.*/m, '')
      render inline: ApplicationController.helpers.br(data), layout: false
    end

    def source_view
      data = @item.rfc822
      render inline: ApplicationController.helpers.br(data), layout: false
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
        @item.destroy_files
      else
        @item.save_to_sent(msg.deliver_now.to_s)
        @item.destroy_files
      end

      render_create true
    end

    def destroy
      raise "403" unless @item.allowed?(:delete, @cur_user)
      render_destroy @item.move_trash
    end

    def set_seen
      render_change :set_seen, @model.set_seen(get_uids).size
    end

    def unset_seen
      render_change :unset_seen, @model.unset_seen(get_uids).size
    end

    def set_star
      render_change :set_star, @model.set_star(get_uids).size
    end

    def unset_star
      render_change :unset_star, @model.unset_star(get_uids).size
    end

    def destroy_all
      render_change :delete, @model.uids_move_trash(get_uids).size
    end

    def copy
      render_change :copy, @model.uids_copy(get_uids, params[:dst]).size
    end

    def move
      render_change :move, @model.uids_move(get_uids, params[:dst]).size
    end

    def render_change(action, count)
      location = params[:redirect].presence || { action: :index }

      multiple = (count == 1) ? '' : 'multiple.'
      notice = t("webmail.notice.#{multiple}#{action}", count: count)

      respond_to do |format|
        format.html { redirect_to location, notice: notice }
        format.json { head :no_content }
      end
    end
end
