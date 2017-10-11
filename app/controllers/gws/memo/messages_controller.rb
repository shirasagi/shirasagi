class Gws::Memo::MessagesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Memo::Message

  before_action :apply_recent_filters, only: [:index]
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy]

  def set_crumbs
    apply_recent_filters
    @crumbs << ['連絡メモ', { action: :index } ]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, from: {@cur_user.id.to_s => 'INBOX.Sent'}  }
  end

  def apply_recent_filters
    return 0 # if inbox.status.recent == 0
    #
    # counts = Webmail::Filter.user(imap.user).enabled.map do |filter|
    #   filter.imap = imap
    #   filter.apply 'INBOX', ['NEW']
    # end
    #
    # update_status
    # counts.inject(:+) || 0
  end

end
