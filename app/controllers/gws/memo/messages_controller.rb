class Gws::Memo::MessagesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Memo::Message

  before_action :deny_with_auth

  before_action :apply_filters, only: [:index], if: -> { params[:folder] == 'INBOX' }
  before_action :set_item, only: [:show, :edit, :update, :send_mdn, :ignore_mdn, :trash, :delete, :destroy, :toggle_star]
  #before_action :redirect_to_appropriate_folder, only: [:show], if: -> { params[:folder] == 'REDIRECT' }
  before_action :set_selected_items, only: [:trash_all, :destroy_all, :set_seen_all, :unset_seen_all,
                                            :set_star_all, :unset_star_all, :move_all]
  before_action :set_folders, only: [:index]
  before_action :set_cur_folder, only: [:index]

  private

  def deny_with_auth
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)
  end

  def set_item
    super
    raise "404" unless @item.readable?(@cur_user, @cur_site)
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_crumbs
    set_cur_folder
    @crumbs << [@cur_site.menu_memo_label || t('mongoid.models.gws/memo/message'), gws_memo_messages_path ]
    if @cur_folder.folder_path != 'INBOX'
      @cur_folder.ancestor_or_self.each do |folder|
        @crumbs << [folder.current_name, gws_memo_messages_path(folder: folder.folder_path)]
      end
    end
  end

  def set_cur_folder
    if params[:folder] =~ /^(INBOX|INBOX\.Trash|INBOX\.Draft|INBOX\.Sent)$/
      @cur_folder = Gws::Memo::Folder.static_items(@cur_user, @cur_site).find{ |dir| dir.folder_path == params[:folder] }
    else
      @cur_folder = Gws::Memo::Folder.user(@cur_user).site(@cur_site).find_by(_id: params[:folder])
    end
  end

  def set_folders
    @folders = Gws::Memo::Folder.static_items(@cur_user, @cur_site) + Gws::Memo::Folder.user(@cur_user).site(@cur_site)
    @folders.each { |folder| folder.site = @cur_site }
  end

  def apply_filters
    @model.site(@cur_site).unfiltered(@cur_user).each do |message|
      message.apply_filters(@cur_user, @cur_site)
    end
  end

  def send_forward_mails
    forward_emails = Gws::Memo::Forward.site(@cur_site).
      in(user_id: @item.member_ids).
      where(default: "enabled").
      pluck(:email).
      select(&:present?)

    return if forward_emails.blank?
    Gws::Memo::Mailer.forward_mail(@item, forward_emails).deliver_now
  end

  #def redirect_to_appropriate_folder
  #  path = @item.from[@cur_user.id.to_s]
  #  if path.present?
  #    redirect_to({ folder: path })
  #  end
  #
  #  path = @item.to[@cur_user.id.to_s]
  #  if path.present?
  #    folter = Gws::Memo::Folder.user(@cur_user).find(path) rescue nil
  #  end
  #
  #  if folter.present?
  #    redirect_to({ folder: folter.id })
  #  elsif path.present?
  #    redirect_to({ folder: path })
  #  else
  #    raise '404'
  #  end
  #end

  public

  def index
    @items = @model.folder(@cur_folder, @cur_user).
      site(@cur_site).
      search(params[:s]).
      page(params[:page]).per(50)
  end

  def new
    @item = @model.new pre_params.merge(fix_params)
    @item.new_memo
  end

  def create
    @item = @model.new get_params
    if params['commit'] == t('gws/memo/message.commit_params_check')
      @item.state = "public"
      notice = t("ss.notice.sent")
    else
      @item.state = "closed"
      notice = t("ss.notice.saved")
    end

    if @item.save
      send_forward_mails
      render_create true, location: { action: :index }, notice: notice
    else
      render_create false, location: { action: :index }, notice: notice
    end
  end

  def show
    @item.set_seen(@cur_user).update if @item.state == "public"
    render
  end

  def edit
    raise "404" unless @item.editable?(@cur_user, @cur_site)
    render
  end

  def update
    @item.attributes = get_params
    raise "404" unless @item.editable?(@cur_user, @cur_site)

    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    if params['commit'] == t('gws/memo/message.commit_params_check')
      @item.state = "public"
      notice = t("ss.notice.sent")
    else
      notice = t("ss.notice.saved")
    end

    if @item.update
      send_forward_mails
      render_update true, location: { action: :index }, notice: notice
    else
      render_update false, location: { action: :index }, notice: notice
    end
  end

  def delete
    render
  end

  def destroy
    render_destroy @item.destroy_from_folder(@cur_user, @cur_folder)
  end

  def destroy_all
    entries = @items.entries
    @items = []

    entries.each do |item|
      if @cur_user.id == item.user_id || item.member?(@cur_user)
        next if item.destroy_from_folder(@cur_user, @cur_folder)
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(entries.size != @items.size)
  end

  def reply
    @item = @model.new pre_params.merge(fix_params)
    item_reply = @model.site(@cur_site).find(params[:id])
    @item.to_member_ids = [item_reply.user_id]
    @item.subject = "Re: #{item_reply.subject}"

    @item.new_memo
    @item.text += "\n\n"
    @item.text += item_reply.text.to_s.gsub(/^/m, '> ')
  end

  def reply_all
    @item = @model.new pre_params.merge(fix_params)
    item_reply = @model.site(@cur_site).find(params[:id])

    @item.to_member_ids = [item_reply.user_id] + item_reply.to_member_ids - [@cur_user.id]
    @item.cc_member_ids = item_reply.cc_member_ids
    @item.subject = "Re: #{item_reply.subject}"

    @item.new_memo
    @item.text += "\n\n"
    @item.text += item_reply.text.to_s.gsub(/^/m, '> ')
  end

  def forward
    @item = @model.new pre_params.merge(fix_params)
    item_forward = @model.site(@cur_site).find(params[:id])
    @item.member_ids = []

    @item.new_memo
    @item.text += "\n\n"
    @item.text += item_forward.text.to_s.gsub(/^/m, '> ')
  end

  def send_mdn
    @item.request_mdn_ids = @item.request_mdn_ids - [@cur_user.id]
    @item.update

    item_mdn = @model.new fix_params
    item_mdn.to_member_ids = [@item.user_id]
    item_mdn.subject = I18n.t("gws/memo/message.mdn.subject", subject: @item.subject)
    item_mdn.text = I18n.t("gws/memo/message.mdn.confirmed", name: @cur_user.long_name, date: Time.zone.now.strftime("%Y/%m/%d %H:%M"))
    item_mdn.format = "text"
    item_mdn.state = "public"
    item_mdn.save

    render_change :send_mdn, redirect: { action: :show }
  end

  def ignore_mdn
    @item.request_mdn_ids = @item.request_mdn_ids - [@cur_user.id]
    @item.update
    render_change :ignore_mdn, redirect: { action: :show }
  end

  def trash
    render_destroy @item.move(@cur_user, 'INBOX.Trash').update
  end

  def trash_all
    @items.each do |item|
      raise "404" unless item.readable?(@cur_user, @cur_site)
      item.move(@cur_user, 'INBOX.Trash').update
    end
    render_destroy_all(false)
  end

  def move_all
    @items.each do |item|
      raise "404" unless item.readable?(@cur_user, @cur_site)
      item.move(@cur_user, params[:path]).update
    end
    render_destroy_all(false)
  end

  def set_seen_all
    @items.each do |item|
      raise "404" unless item.readable?(@cur_user, @cur_site)
      item.set_seen(@cur_user).update
    end
    render_destroy_all(false)
  end

  def unset_seen_all
    @items.each do |item|
      raise "404" unless item.readable?(@cur_user, @cur_site)
      item.unset_seen(@cur_user).update
    end
    render_destroy_all(false)
  end

  def toggle_star
    render_destroy @item.toggle_star(@cur_user).update, location: { action: params[:location] }
  end

  def set_star_all
    @items.each do |item|
      raise "404" unless item.readable?(@cur_user, @cur_site)
      item.set_star(@cur_user).update
    end
    render_destroy_all(false)
  end

  def unset_star_all
    @items.each do |item|
      raise "404" unless item.readable?(@cur_user, @cur_site)
      item.unset_star(@cur_user).update
    end
    render_destroy_all(false)
  end

  def render_change(action, opts = {})
    location = params[:redirect].presence || opts[:redirect] || { action: :index }

    respond_to do |format|
      format.html { redirect_to location, notice: t("gws/memo/message.notice.#{action}") }
      format.json { render json: { action: params[:action], notice: t("gws/memo/message.notice.#{action}") } }
    end
  end
end
