class Sns::Message::Apis::UnseenController < ApplicationController
  include Sns::BaseFilter

  def index
    count = Sns::Message::Thread.
      where(unseen_member_ids: @cur_user.id).
      size

    render text: count
  end
end
