class Gws::Memo::MessagesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Memo::Message

  before_action :apply_recent_filters, only: [:index]
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :toggle_star]
  before_action :set_selected_items, only: [:destroy_all, :set_seen_all, :unset_seen_all, :set_star_all, :unset_star_all]
  before_action :set_group_navi, only: [:index]

  def set_crumbs
    apply_recent_filters
    @crumbs << ['連絡メモ', { action: :index } ]
  end

  MemoGroup = Struct.new(:name, :path, :unseen?, :unseen_count)

  def set_group_navi
    @group_navi ||= []
    @group_navi << MemoGroup.new('受信トレイ', 'INBOX', false, 0)
    @group_navi << MemoGroup.new('ゴミ箱', 'INBOX.Trash', false, 0)
    @group_navi << MemoGroup.new('送信済み', 'INBOX.Sent', false, 0)
    @group_navi << MemoGroup.new('フォルダA', BSON::ObjectId.new.to_s, false, 0)
    @group_navi << MemoGroup.new('フォルダB', BSON::ObjectId.new.to_s, false, 0)
    @group_navi << MemoGroup.new('フォルダC', BSON::ObjectId.new.to_s, true, 3)
    @group_navi << MemoGroup.new('フォルダD', BSON::ObjectId.new.to_s, false, 0)
    @group_navi << MemoGroup.new('フォルダE', BSON::ObjectId.new.to_s, false, 0)
    @group_navi << MemoGroup.new('フォルダF', BSON::ObjectId.new.to_s, false, 0)
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

  def show
    raise '403' unless @item.allowed?(:read, @cur_user, site: @cur_site)
    @item.set_seen(@cur_user).update
    render
  end

  def set_seen_all
    @items.each{ |item| item.set_seen(@cur_user).update }
    render_destroy_all(false)
  end

  def unset_seen_all
    @items.each{ |item| item.unset_seen(@cur_user).update }
    render_destroy_all(false)
  end

  def toggle_star
    render_destroy @item.toggle_star(@cur_user).update
  end

  def set_star_all
    @items.each{ |item| item.set_star(@cur_user).update }
    render_destroy_all(false)
  end

  def unset_star_all
    @items.each{ |item| item.unset_star(@cur_user).update }
    render_destroy_all(false)
  end
end
