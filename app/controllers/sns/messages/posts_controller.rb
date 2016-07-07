class Sns::Messages::PostsController < ApplicationController
  include Sns::BaseFilter
  include Sns::CrudFilter

  model Sns::Message::Post

  before_action :set_thread

  private
    def set_thread
      @thread ||= Sns::Message::Thread.find params[:thread_id]
      #TODO: readable
      raise '404' unless @thread
    end

    def set_crumbs
      set_thread
      @crumbs << [:"messages", sns_messages_path]
      @crumbs << [:"threads", sns_messages_threads_path]
      @crumbs << [@thread.id, sns_messages_thread_path(id: @thread)]
    end

    def fix_params
      { cur_user: @cur_user, thread_id: @thread.id }
    end

  public
    def index
      @items = @model.
        where(thread_id: @thread.id).
        page(params[:page]).
        per(20)
    end
end
