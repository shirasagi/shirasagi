class Sns::Message::PostsController < ApplicationController
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
      @crumbs << [:"sns.message", sns_message_threads_path]
      @crumbs << [@thread.name(@cur_user), { action: :index }]
    end

    def fix_params
      { cur_user: @cur_user, thread_id: @thread.id }
    end

    def crud_redirect_url
      { action: :index }
    end

  public
    def index
      @items = @model.
        where(thread_id: @thread.id).
        search(params[:s]).
        page(params[:page]).
        per(20)

      @thread.set_seen(@cur_user)
    end

    def edit
      raise '404'
    end

    def update
      raise '404'
    end
end
