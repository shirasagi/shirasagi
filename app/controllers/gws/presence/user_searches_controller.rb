class Gws::Presence::UserSearchesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Presence::UserFilter

  private

  def set_crumbs
    set_search_params
    set_group
    set_titles
    @crumbs << [t("modules.gws/presence"), gws_presence_user_searches_path]
  end

  def set_group
    @groups = Gws::Group.active.site(@cur_site)
    @group = @groups.where(id: @s[:group_id]).first
    @custom_groups = Gws::CustomGroup.site(@cur_site).member(@cur_user)
    @custom_group = @custom_groups.where(id: @s[:custom_group_id]).first
  end

  def set_titles
    @titles = Gws::UserTitle.active.site(@cur_site)
  end

  def set_search_params
    @s = OpenStruct.new params[:s]
    @s[:group_id] ||= @cur_group.id
    @s[:limit] ||= 100
  end

  def set_items
    @items ||= @model.site(@cur_site).
      active.
      readable_users(@cur_user, site: @cur_site)
  end

  def items
    @items = @model.site(@cur_site).active.readable_users(@cur_user, site: @cur_site).order_by_title(@cur_site).
      page(params[:page]).per(@s[:limit])
    @items = @items.in(group_ids: @s[:group_id].to_i) if @s[:group_id].present?
    if @s[:custom_group_id].present?
      custom_group = @custom_groups.where(id: @s[:custom_group_id]).first
      if custom_group
        @items = @items.where("$and" => [{ id: { "$in" => custom_group.overall_member_ids } }])
      end
    end
    @items = @items.in(title_ids: @s[:title_id].to_i) if @s[:title_id].present?
    if @s[:keyword].present?
      or_conds = []
      user_presences = Gws::UserPresence.site(@cur_site).
        in(user_id: @items.pluck(:id)).
        keyword_in(@s[:keyword], :manager_name, :department)
      or_conds << { id: { "$in" => user_presences.pluck(:user_id) } }
      keyword = @s[:keyword].split(/[\s　]+/).uniq.compact.map { |w| /#{::Regexp.escape(w)}/i } if @s[:keyword].is_a?(String)
      keyword[0..4].each do |w|
        or_conds << { name: w }
        or_conds << { kana: w }
        or_conds << { tel_ext: w }
      end
      @items = @items.where("$and" => [{ "$or" => or_conds }])
    end
    @items
  end

  public

  def index
    items
  end

  def user_edit
    raise "404" unless @manageable

    items

    if request.get? || request.head?
      return
    end

    entries = @items.entries
    @items = []
    result = true

    entries.each do |item|
      begin
        user_presence = item.user_presence(@cur_site)
        user_presence.plan = params.dig(:item, item.id.to_s, :plan)
        user_presence.memo = params.dig(:item, item.id.to_s, :memo)
        user_presence.manager_name = params.dig(:item, item.id.to_s, :manager_name)
        user_presence.department = params.dig(:item, item.id.to_s, :department)
        if user_presence.changed? && !user_presence.save
          result = false
        end
        item.tel_ext = params.dig(:item, item.id.to_s, :tel_ext)
        if item.changed? && !item.save
          result = false
        end
        @items << item
      rescue
        result = false
      end
    end
    render_confirmed_all(result, location: { action: :index, page: params[:page] }, notice: t("ss.notice.saved"))
  end
end
