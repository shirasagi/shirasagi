class Sns::Message::ThreadsController < ApplicationController
  include Sns::BaseFilter
  include Sns::CrudFilter
  include Sns::Message::MailFilter

  model Sns::Message::Thread

  private
    def set_crumbs
      @crumbs << [:"sns.message", sns_message_threads_path]
    end

    def fix_params
      { cur_user: @cur_user }
    end

    def crud_redirect_url
      if params[:action] =~ /destroy/
        { action: :index }
      else
        sns_message_thread_posts_path(thread_id: @item.id)
      end
    end

  public
    def index
      @items = @model.
        allow(:read, @cur_user).
        search(params[:s]).
        page(params[:page]).
        per(20)
    end

    def create
      @item = @model.new get_params

      if thread = @item.recycle_create
        @item = thread
        post = thread.posts.reorder(created: -1).first
        send_notification_mail(post)
      end

      render_create thread
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
