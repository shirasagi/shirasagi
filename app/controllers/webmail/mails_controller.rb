class Webmail::MailsController < ApplicationController
  include Webmail::BaseFilter
  include Webmail::ImapFilter
  include Sns::CrudFilter

  model Webmail::Mail

  before_action :set_mailbox
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :attachment, :downlowd]

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
      @item.set_seen
    end

    def attachment
      @item.attachments.each_with_index do |at, idx|
        next unless idx == params[:idx].to_i
        return send_data at.read, filename: at.filename, content_type: at.content_type
      end

      raise '404'
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
