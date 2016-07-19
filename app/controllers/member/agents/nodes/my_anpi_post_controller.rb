class Member::Agents::Nodes::MyAnpiPostController < ApplicationController
  include Cms::NodeFilter::View
  include Member::LoginFilter
  include Cms::PublicFilter::Crud
  helper Member::MypageHelper

  model Board::AnpiPost
  prepend_view_path "app/views/member/agents/nodes/my_anpi_post"
  before_action :deny
  before_action :set_groups
  before_action :set_cur_group, only: [:index, :map]
  before_action :set_items, only: [:index, :map]
  before_action :set_map_center, only: [:map]
  before_action :check_owner, only: [:edit, :update, :delete, :destroy, :destroy_all]

  private
    def fix_params
      { cur_site: @cur_site, cur_node: @cur_node, cur_member: @cur_member }
    end

    def pre_params
      if params[:action] == 'new'
        params = { name: @cur_member.name }
        params[:kana] = @cur_member.try(:kana)
        params[:tel] = @cur_member.try(:tel)
        params[:addr] = @cur_member.try(:addr)
        params[:sex] = @cur_member.try(:sex)
        params[:age] = @cur_member.try(:age)
        params
      else
        {}
      end
    end

    def deny
      if @cur_node.deny_ips.present?
        remote_ip = request.env["HTTP_X_REAL_IP"] || request.remote_ip
        @cur_node.deny_ips.each do |deny_ip|
          raise "404" if remote_ip =~ /^#{deny_ip}/
        end
      end
    end

    def set_groups
      @cur_member_groups ||= Member::Group.site(@cur_site).and_member(@cur_member).order_by(id: 1)
    end

    def set_cur_group
      set_groups
      return @cur_member_group if @cur_member_group.present?

      group_id = params[:g].presence
      group_id = Integer(group_id) rescue nil if group_id.present?
      @cur_member_group ||= @cur_member_groups.where(id: group_id).first if group_id.present?
      @cur_member_group ||= @cur_member_groups.first
    end

    def check_owner
      raise "403" unless @item.owned?(@cur_member)
    end

    def set_items
      if @cur_member_group.present?
        @items = Board::AnpiPost.site(@cur_site).
          and_member_group(@cur_member_group).
          and_public_for(@cur_member).
          order_by(released: -1).
          page(params[:page]).per(20)
      else
        @items = Board::AnpiPost.site(@cur_site).
          and_owned_by(@cur_member).
          order_by(released: -1).
          page(params[:page]).per(20)
      end
    end

    def square_distance(lhs, rhs)
      (lhs[0] - rhs[0]) ** 2 + (lhs[1] - rhs[1]) ** 2
    end

    def set_map_center
      @map_center = @cur_node.map_center.presence || Map::Extensions::Loc[*SS.config.map.map_center]
      return if @items.blank?

      # collect locations
      locs = @items.map do |item|
        next nil if item.point.blank?
        loc = item.point.loc
        next nil if loc.blank?
        next nil if loc.lat == 0 || loc.lng == 0
        loc
      end

      # select valid locations
      locs = locs.compact.select { |loc| square_distance(loc, @map_center) < 10 }
      return if locs.blank?

      # min: top left corner of locations, max: bottom right corner of locations
      min = [10_000, 10_000]
      max = [-10_000, -10_000]
      locs.each do |loc|
        min[0] = loc[0] if min[0] > loc[0]
        min[1] = loc[1] if min[1] > loc[1]
        max[0] = loc[0] if max[0] < loc[0]
        max[1] = loc[1] if max[1] < loc[1]
      end

      @map_center = Map::Extensions::Loc[(min[0] + max[0]) / 2, (min[1] + max[1]) / 2]
    end

  public
    def index
    end

    def others_new
      @item = @model.new pre_params.merge(fix_params)
    end

    def others_create
      @item = @model.new get_params
      render_create @item.save, location: @cur_node.url
    end

    def map
    end
end
