class Member::GroupMembersController < ApplicationController
  include Cms::BaseFilter
  # include SS::CrudFilter
  include Cms::CrudFilter

  model Member::GroupMember

  navi_view "member/group_members/navi"

  private
    def set_crumbs
      set_member_group
      @crumbs << [:"member.group", member_group_path(id: @cur_member_group)]
      @crumbs << [:"member.group_member", action: :index]
    end

    # def fix_params
    #   { cur_site: @cur_site }
    # end

    def set_member_group
      @cur_member_group ||= Member::Group.site(@cur_site).find(params[:group_id])
    end

    def set_item
      set_member_group
      @item = @cur_member_group.members.find params[:id]
      @item.attributes = fix_params
    end

  public
    def index
      set_member_group
      raise "403" unless @cur_member_group.allowed?(:read, @cur_user, site: @cur_site)

      @items = @cur_member_group.members.
        order_by(id: 1).
        page(params[:page]).per(50)
    end

    def show
      raise "403" unless @cur_member_group.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)
      render
    end

    def new
      set_member_group
      @item = @cur_member_group.members.new pre_params.merge(fix_params)
      raise "403" unless @cur_member_group.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
    end

    def create
      set_member_group
      @item = @cur_member_group.members.new get_params
      raise "403" unless @cur_member_group.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
      render_create @item.save
    end

    def edit
      raise "403" unless @cur_member_group.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
      if @item.is_a?(Cms::Addon::EditLock)
        unless @item.acquire_lock
          redirect_to action: :lock
          return
        end
      end
      render
    end

    def update
      @item.attributes = get_params
      @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
      raise "403" unless @cur_member_group.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
      render_update @item.update
    end

    def delete
      raise "403" unless @cur_member_group.allowed?(:delete, @cur_user, site: @cur_site, node: @cur_node)
      render
    end

    def destroy
      raise "403" unless @cur_member_group.allowed?(:delete, @cur_user, site: @cur_site, node: @cur_node)
      @cur_member_group.in_remove_member_ids = [@item.member_id]
      success = @cur_member_group.save
      @cur_member_group.errors.full_messages.each do |msg|
        @item.errors.add :base, msg
      end
      render_destroy success
    end
end
