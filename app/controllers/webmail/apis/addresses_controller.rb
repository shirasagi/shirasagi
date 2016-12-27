class Webmail::Apis::AddressesController < ApplicationController
  include Sns::BaseFilter
  include SS::AjaxFilter

  model Webmail::Address

  #before_action :set_root_group
  #before_action :set_selected_group
  #before_action :set_groups
  before_action :set_multi
  before_action :set_inherit_params

  private
    def set_root_group
      @root_group = @cur_user.groups.active.find params[:group]
    end

    def set_groups
      groups = @root_group.descendants.active
      @groups = groups.tree_sort(root_name: @root_group.name)
    end

    def set_selected_group
      group_id = params.dig(:s, :group)
      return @group = @root_group if group_id.blank?
      @group = @root_group.descendants.active.find(group_id) rescue @root_group
    end

    def set_inherit_params
      @inherit_keys = [:single]
    end

    def set_multi
      @multi = params[:single].blank?
    end

  public
    def index
      @items = @model.
        user(@cur_user).
        search(params[:s]).
        page(params[:page]).
        per(50)
    end
end
