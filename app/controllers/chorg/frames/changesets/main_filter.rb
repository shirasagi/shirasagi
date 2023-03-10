module Chorg::Frames::Changesets::MainFilter
  extend ActiveSupport::Concern

  included do
    layout "chorg/item_frame"
    model Chorg::Changeset

    helper_method :type, :cur_revision, :source_groups, :first_source_group
  end

  private

  def cur_revision
    @revision ||= Chorg::Revision.all.site(@cur_site).find(params[:rid])
  end

  def fix_params
    { cur_revision: cur_revision, cur_type: type }
  end

  def source_groups
    @source_groups ||= begin
      if @item.sources.blank?
        Cms::Group.none
      else
        ids = @item.sources.map { |source| source["id"] }.select(&:present?)
        if ids.blank?
          Cms::Group.none
        else
          Cms::Group.all.in(id: ids).site(@cur_site).reorder(order: 1, name: 1)
        end
      end
    end
  end

  def first_source_group
    return @first_source_group if instance_variable_defined?(:@first_source_group)
    @first_source_group = source_groups.first
  end

  public

  def create
    @item = @model.new get_params
    if params[:reload]
      @item.send(:filter_source_blank_ids)
      @item.send(:set_source_names)
      @reload = true
      render :new
      return
    end

    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
    unless @item.save
      render template: "new"
      return
    end

    flash[:notice] = t("ss.notice.saved")
    json = { status: 302, location: chorg_revision_path(id: cur_revision) }
    render json: json, status: :ok, content_type: json_content_type
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    if params[:reload]
      @item.send(:filter_source_blank_ids)
      @item.send(:set_source_names)
      @reload = true
      render :edit
      return
    end

    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
    unless @item.save
      render template: "edit"
      return
    end

    flash[:notice] = t("ss.notice.saved")
    json = { status: 302, location: chorg_revision_path(id: cur_revision) }
    render json: json, status: :ok, content_type: json_content_type
  end
end
