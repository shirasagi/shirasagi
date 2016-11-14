class Webmail::MailsController < ApplicationController
  include Webmail::BaseFilter
  include Webmail::ImapFilter
  include Sns::CrudFilter

  model Webmail::Mail

  before_action :set_mailbox
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy,
                                  :attachment, :download, :header_view, :source_view]

  private
    def set_crumbs
      @crumbs << [:'webmail.mail', { action: :index } ]
    end

    def set_mailbox
      @mailbox = params[:box]
    end

    def fix_params
      { cur_user: @cur_user }
    end

    def set_item
      set_mailbox
      @item = @model.where(mailbox: @mailbox).imap_find params[:id].to_i
    end

    def crud_redirect_url
      { action: :index }
    end

  public
    def index
      @items = @model.
        where(mailbox: @mailbox).
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

    def set_seen
      change_flag(:set_seen)
    end

    def unset_seen
      change_flag(:unset_seen)
    end

    def set_star
      change_flag(:set_star)
    end

    def unset_star
      change_flag(:unset_star)
    end

    def change_flag(action)
      (params[:ids] || [params[:id]]).each do |id|
        item = @model.where(mailbox: @mailbox).imap_find(id.to_i) rescue nil
        item.try(action) if item
      end

      respond_to do |format|
        format.html { redirect_to({ action: :index }, { notice: t('webmail.notice.changed') }) }
        format.json { head :no_content }
      end
    end

    def create
      @item = @model.new get_params

      send_params = {
        from: "#{@cur_user.name} <#{@cur_user.email}>",
        to: @item.to,
        subject: @item.subject,
        body: @item.text
      }
      msg = SS::Mailer.new_message(send_params).deliver_now

      render_create true
    end

    def destroy
      raise "403" unless @item.allowed?(:delete, @cur_user)
      render_destroy @item.leave_member(@cur_user)
    end

    def destroy_all
      entries = @items.entries
      @items = []

      entries.each do |item|
        if item.allowed?(:delete, @cur_user)
          next if item.leave_member(@cur_user)
        else
          item.errors.add :base, :auth_error
        end
        @items << item
      end
      render_destroy_all(entries.size != @items.size)
    end
end
