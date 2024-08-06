module Gws::Apis::CategoryFilter
  extend ActiveSupport::Concern

  included do
    before_action :set_category
  end

  private

  def set_category
    @categories = @model.site(@cur_site).readable(@cur_user, site: @cur_site).tree_sort

    category_id = params.dig(:s, :category).presence
    @category = @model.where(id: category_id).first if category_id.present?
  end

  public

  def index
    @multi = params[:single].blank?

    criteria = @model.site(@cur_site)
    criteria = criteria.readable(@cur_user, site: @cur_site)
    criteria = criteria.search(params[:s])
    if @category
      criteria = criteria.where("i18n_name.#{I18n.default_locale}" => /^#{::Regexp.escape(@category.i18n_default_name)}\//)
    end
    @items = criteria.tree_sort
    @items = Kaminari.paginate_array(@items.to_a).page(params[:page]).per(50)
  end
end
