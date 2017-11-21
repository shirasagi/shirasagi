module Gws::Portal::PortletModel
  extend ActiveSupport::Concern
  extend SS::Translation
  include Gws::Addon::Portal::Portlet::Free
  include Gws::Addon::Portal::Portlet::Link
  include Gws::Addon::Portal::Portlet::Reminder

  PORTLETS = {
    free:     { size_x: 2, size_y: 2, addons: [Gws::Addon::Portal::Portlet::Free] },
    links:    { size_x: 2, size_y: 3, addons: [Gws::Addon::Portal::Portlet::Link] },
    schedule: { size_x: 4, size_y: 2 },
    reminder: { size_x: 2, size_y: 3, addons: [Gws::Addon::Portal::Portlet::Reminder] },
    board:    { size_x: 2, size_y: 3 },
    monitor:  { size_x: 2, size_y: 3 },
    share:    { size_x: 2, size_y: 3 },
  }.freeze

  included do
    field :name, type: String
    field :portlet_model, type: String
    field :grid_data, type: Hash

    permit_params :name, :portlet_model

    validates :name, presence: true
    validates :portlet_model, inclusion: { in: PORTLETS.keys.map(&:to_s) }
    validates :setting_id, presence: true

    after_validation :set_default_grid_data, if: ->{ grid_data.blank? }

    default_scope -> {
      order_by "grid_data.row" => 1, "grid_data.col" => 1
    }
  end

  def portlet_model_options
    PORTLETS.keys.map { |k| [I18n.t("gws/portal.portlets.#{k}.name"), k] }
  end

  def portlet_model_enabled?
    portlet_model.present? && PORTLETS.key?(portlet_model.to_sym)
  end

  def portlet_addons
    self.class.portlet_addons(portlet_model)
  end

  def default_grid_data
    PORTLETS[portlet_model.to_sym].slice(:size_x, :size_y)
  end

  def view_file
    "gws/portal/portlets/#{portlet_model}/index.html.erb"
  end

  def portlet_id_class
    "portlet-id-#{id}"
  end

  def portlet_model_class
    "portlet-model-#{portlet_model}"
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

    def portlet_model(type)
      {
        type: type,
        name: I18n.t("gws/portal.portlets.#{type}.name"),
        text: I18n.t("gws/portal.portlets.#{type}.text"),
      }
    end

    def default_portlet(type)
      item = self.new(portlet_model: type)
      item.name = I18n.t("gws/portal.portlets.#{type}.name")
      item.grid_data = item.default_grid_data
      item
    end

    def portlet_addons(type)
      portlets = PORTLETS[type.to_sym][:addons] || []
      self.addons.select do |addon|
        addon.type.nil? || portlets.include?(addon.klass)
      end
    end
  end
end
