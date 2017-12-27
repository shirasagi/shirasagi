class Gws::Memo::MessagesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Memo::Message

  before_action :deny_with_auth

  before_action :apply_filters, only: [:index], if: -> { params[:folder] == 'INBOX' }
  before_action :set_item, only: [:show, :edit, :update, :trash, :delete, :destroy, :toggle_star]
  before_action :redirect_to_appropriate_folder, only: [:show], if: -> { params[:folder] == 'REDIRECT' }
  before_action :set_selected_items, only: [:trash_all, :destroy_all, :set_seen_all, :unset_seen_all,
                                            :set_star_all, :unset_star_all, :move_all]
  before_action :set_folders, only: [:index]
  before_action :set_cur_folder, only: [:index]

  private

  def deny_with_auth
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)
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

  def set_item
    super
    return if (@cur_user.id == @item.user_id || @item.member?(@cur_user))
    raise "403"
  end

  def set_cur_folder
    if params[:folder] =~ /INBOX|INBOX.Trash|INBOX.Draft|INBOX.Sent|REDIRECT/
      @cur_folder = Gws::Memo::Folder.static_items(@cur_user, @cur_site).find{ |dir| dir.folder_path == params[:folder] }
    else
      @cur_folder = Gws::Memo::Folder.user(@cur_user).find_by(_id: params[:folder])
    end
  end

  def set_folders
    @folders = Gws::Memo::Folder.static_items(@cur_user, @cur_site) + Gws::Memo::Folder.user(@cur_user)
    @folders.each { |folder| folder.site = @cur_site }
  end

  def apply_filters
    @model.user(@cur_user).unfiltered(@cur_user).each{ |message| message.apply_filters(@cur_user).update }
  end

  #def from_folder
  #  (params[:commit] == I18n.t('ss.buttons.draft_save')) ? 'INBOX.Draft' : 'INBOX.Sent'
  #end

  def redirect_to_appropriate_folder
    path = @item.from[@cur_user.id.to_s]
    if path.present?
      redirect_to({ folder: path })
    end

    path = @item.to[@cur_user.id.to_s]
    if path.present?
      folter = Gws::Memo::Folder.user(@cur_user).find(path) rescue nil
    end

    if folter.present?
      redirect_to({ folder: folter.id })
    elsif path.present?
      redirect_to({ folder: path })
    else
      raise '404'
    end
  end

  public

  def index
    @items = @model.folder(@cur_folder, @cur_user).
      search(params[:s]).
      page(params[:page]).per(50)
  end

  def new
    @item = @model.new pre_params.merge(fix_params)
    @item.new_memo
  end

  def reply
    @item = @model.new pre_params.merge(fix_params)
    item_reply = @model.find(params[:id])
    @item.member_ids = item_reply.member_ids
    @item.subject = "Re: #{item_reply.subject}"

    @item.new_memo
    @item.text += "\n\n"
    @item.text += item_reply.text.to_s.gsub(/^/m, '> ')
  end

  def create
    @item = @model.new get_params
    if params['commit'] == t('gws/memo/message.commit_params_check')
      @item.send_date = Time.zone.now
      @item.state = "public"

      # 外部メールへの転送
      forward_setting = Gws::Memo::Forward.user(@cur_user).first
      if forward_setting && forward_setting.default == "enabled"
        Gws::Memo::Mailer.forward_mail(@item, @cur_user, @cur_site, forward_setting.email).deliver_now
      end
    else
      @item.state = "closed"
    end
    #render_create @item.save, location: { action: :show, id: @item, folder: from_folder }
    render_create @item.save, location: { action: :index }
  end

  def forward
    forward_params = params.require(:item).permit(:subject, :text, :html, :format)
    @item = @model.new pre_params.merge(fix_params).merge(forward_params)
    render :new
  end

  def update
    @item.attributes = get_params
    raise '403' unless @cur_user.id == @item.user_id

    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    if params['commit'] == t('gws/memo/message.commit_params_check')
      @item.send_date = Time.zone.now
      @item.state = "public"

      # 外部メールへの転送
      forward_setting = Gws::Memo::Forward.user(@cur_user).first
      if forward_setting && forward_setting.default == "enabled"
        Gws::Memo::Mailer.forward_mail(@item, @cur_user, @cur_site, forward_setting.email).deliver_now
      end
    end
    render_update @item.update, location: { action: :show, id: @item, folder: params[:folder] }
  end

  def show
    raise '403' unless (@cur_user.id == @item.user_id || @item.member?(@cur_user))
    @item.set_seen(@cur_user).update
    render
  end

  def trash
    raise '403' unless (@cur_user.id == @item.user_id || @item.member?(@cur_user))
    render_destroy @item.move(@cur_user, 'INBOX.Trash').update
  end

  def trash_all
    @items.each do |item|
      raise '403' unless (@cur_user.id == item.user_id || item.member?(@cur_user))
      item.move(@cur_user, 'INBOX.Trash').update
    end
    render_destroy_all(false)
  end

  def move_all
    @items.each do |item|
      raise '403' unless (@cur_user.id == item.user_id || item.member?(@cur_user))
      item.move(@cur_user, params[:path]).update
    end
    render_destroy_all(false)
  end

  def set_seen_all
    @items.each do |item|
      raise '403'unless (@cur_user.id == item.user_id || item.member?(@cur_user))
      item.set_seen(@cur_user).update
    end
    render_destroy_all(false)
  end

  def unset_seen_all
    @items.each do |item|
      raise '403' unless (@cur_user.id == item.user_id || item.member?(@cur_user))
      item.unset_seen(@cur_user).update
    end
    render_destroy_all(false)
  end

  def toggle_star
    raise '403' unless (@cur_user.id == @item.user_id || @item.member?(@cur_user))
    render_destroy @item.toggle_star(@cur_user).update, location: { action: params[:location] }
  end

  def set_star_all
    @items.each do |item|
      raise '403' unless (@cur_user.id == item.user_id || item.member?(@cur_user))
      item.set_star(@cur_user).update
    end
    render_destroy_all(false)
  end

  def unset_star_all
    @items.each do |item|
      raise '403' unless (@cur_user.id == item.user_id || item.member?(@cur_user))
      item.unset_star(@cur_user).update
    end
    render_destroy_all(false)
  end
end
