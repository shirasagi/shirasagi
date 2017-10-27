module Gws::Portal::PortletModel
  extend ActiveSupport::Concern
  extend SS::Translation
  include Gws::Addon::Portal::Portlet::Free
  include Gws::Addon::Portal::Portlet::Link

  PORTLET_MODELS = {
    free:     { size_x: 2, size_y: 2, addons: [Gws::Addon::Portal::Portlet::Free] },
    links:    { size_x: 2, size_y: 3, addons: [Gws::Addon::Portal::Portlet::Link] },
    schedule: { size_x: 4, size_y: 2 },
    reminder: { size_x: 2, size_y: 3 },
    board:    { size_x: 2, size_y: 3 },
  }.freeze

  included do
    field :name, type: String
    field :portlet_model, type: String
    field :grid_data, type: Hash

    #belongs_to :setting, class_name: 'Gws::Portal::***Setting'

    permit_params :name, :portlet_model

    validates :name, presence: true
    validates :portlet_model, inclusion: { in: PORTLET_MODELS.keys.map(&:to_s) }
    validates :setting_id, presence: true

    after_validation :set_default_grid_data, if: ->{ grid_data.blank? }

    default_scope -> {
      order_by "grid_data.row" => 1, "grid_data.col" => 1
    }
  end

  def portlet_models
    PORTLET_MODELS.keys.map do |key|
      {
        key: key,
        name: I18n.t("gws/portal.portlets.#{key}.name"),
        text: I18n.t("gws/portal.portlets.#{key}.text"),
      }
    end
  end

  def portlet_model_options
    PORTLET_MODELS.keys.map { |k| [I18n.t("gws/portal.portlets.#{k}.name"), k] }
  end

  def portlet_model_enabled?
    portlet_model.present? && PORTLET_MODELS.key?(portlet_model.to_sym)
  end

  def default_grid_data
    PORTLET_MODELS[portlet_model.to_sym].slice(:size_x, :size_y)
  end

  def portlet_addons
    addons = PORTLET_MODELS[portlet_model.to_sym][:addons] || []
    self.class.addons.select do |addon|
      addons.include?(addon.klass)
    end
  end

  def portlet_view_file
    "gws/portal/portlets/#{portlet_model}/index.html.erb"
  end

  private

  def set_default_grid_data
    self.grid_data = default_grid_data
  end

  module ClassMethods
    def search(params)
      criteria = where({})
      return criteria if params.blank?

      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name
      end
      criteria
    end

    def default_portlet(key)
      item = self.new(portlet_model: key)
      item.name = I18n.t("gws/portal.portlets.#{key}.name")
      item.grid_data = item.default_grid_data
      item
    end
  end
end
