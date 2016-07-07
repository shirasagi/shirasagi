class Sns::Messages::ThreadsController < ApplicationController
  include Sns::BaseFilter
  include Sns::CrudFilter

  model Sns::Message::Thread

  private
    def set_crumbs
      @crumbs << [:"messages", sns_messages_path]
      @crumbs << [:"threads", sns_messages_threads_path]
    end

    def fix_params
      { cur_user: @cur_user }
    end

  public
    def index
      @items = @model.
        where(member_ids: @cur_user.id).
        page(params[:page]).
        per(20)
    end

    def create
      @item = @model.new get_params

      thread = @item.recycle_create
      @item = thread if thread

      render_create thread
    end
end
