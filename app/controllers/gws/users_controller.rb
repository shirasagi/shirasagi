class Gws::UsersController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::User

  prepend_view_path "app/views/sys/users"
  # navi_view "gws/main/conf_navi"
  navi_view 'gws/user_conf/navi'

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.gws/user"), gws_users_path]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def group_ids
    if params[:s].present? && params[:s][:group].present?
      @group = @cur_site.descendants.active.find(params[:s][:group]) rescue nil
    end
    @group ||= @cur_site
    @group_ids ||= @cur_site.descendants.active.in_group(@group).pluck(:id)
  end

  def build_form_data
    return if params[:custom].blank?

    cur_form = Gws::UserForm.site(@cur_site).order_by(id: 1, created: 1).first
    return if cur_form.blank? || cur_form.state_closed?

    custom = params.require(:custom)
    new_column_values = cur_form.build_column_values(custom)

    if @item.persisted?
      form_data = Gws::UserFormData.site(@cur_site).user(@item).form(cur_form).order_by(id: 1, created: 1).first_or_create
      form_data.cur_site = @cur_site
      form_data.cur_form = cur_form
      form_data.cur_user = @item
    else
      form_data = Gws::UserFormData.new
      form_data.cur_site = @cur_site
      form_data.cur_form = cur_form
    end
    form_data.update_column_values(new_column_values)
    form_data
  end

  def save_form_data
    form_data = build_form_data
    return if form_data.blank?

    form_data.save
    form_data
  end

  public

  def index
    @groups = @cur_site.descendants.active.tree_sort(root_name: @cur_site.name)

    @items = @model.site(@cur_site).
      state(params.dig(:s, :state)).
      allow(:read, @cur_user, site: @cur_site).
      in(group_ids: group_ids).
      search(params[:s]).
      order_by_title(@cur_site).
      page(params[:page]).per(50)
  end

  def create
    @item = @model.new get_params
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    form_data = build_form_data
    result = @item.valid?
    if form_data.present? && form_data.invalid?
      @item.errors[:base] += form_data.errors.full_messages
      result = false
    end

    if result
      result = @item.save
    end

    if result && form_data.present?
      form_data.cur_user = @item
      form_data.save!
    end

    render_create result
  end

  def update
    other_group_ids = Gws::Group.nin(id: Gws::Group.site(@cur_site).pluck(:id)).in(id: @item.group_ids).pluck(:id)
    other_role_ids = Gws::Role.nin(id: Gws::Role.site(@cur_site).pluck(:id)).in(id: @item.gws_role_ids).pluck(:id)

    @item.attributes = get_params
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    result = @item.valid?
    form_data = save_form_data
    if form_data.invalid?
      @item.errors[:base] += form_data.errors.full_messages
      result = false
    end

    if result
      result = @item.save

      @item.add_to_set(group_ids: other_group_ids)
      @item.add_to_set(gws_role_ids: other_role_ids)
      raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    end

    render_update result
  end

  def destroy
    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render_destroy @item.disable
  end

  def destroy_all
    disable_all
  end

  def download
    csv = @model.unscoped.site(@cur_site).order_by_title(@cur_site).to_csv(site: @cur_site)
    send_data csv.encode("SJIS", invalid: :replace, undef: :replace), filename: "gws_users_#{Time.zone.now.to_i}.csv"
  end

  def download_template
    csv = @model.unscoped.where(:_id.exists => false).to_csv(site: @cur_site)
    send_data csv.encode("SJIS", invalid: :replace, undef: :replace), filename: "gws_users_template.csv"
  end

  def import
    return if request.get?
    @item = @model.new get_params
    @item.cur_site = @cur_site
    result = @item.import
    flash.now[:notice] = t("ss.notice.saved") if !result && @item.imported > 0
    render_create result, location: { action: :index }, render: { file: :import }
  end
end
