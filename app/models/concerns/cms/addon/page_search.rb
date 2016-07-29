module Cms::Addon
  module PageSearch
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :search_name, type: String
      field :search_filename, type: String
      field :search_state, type: String
      field :search_approver_state, type: String
      field :search_released_start, type: DateTime
      field :search_released_close, type: DateTime
      field :search_updated_start, type: DateTime
      field :search_updated_close, type: DateTime
      embeds_ids :search_categories, class_name: "Cms::Node"
      embeds_ids :search_groups, class_name: "SS::Group"
      embeds_ids :search_nodes, class_name: "Cms::Node"
      field :search_routes, type: SS::Extensions::Words, default: []

      permit_params :search_name, :search_filename, :search_state, :search_approver_state
      permit_params :search_released_start, :search_released_close, :search_updated_start, :search_updated_close
      permit_params search_category_ids: [], search_group_ids: [], search_node_ids: []
      permit_params search_routes: []

      before_validation :normalize_search_routes
      validates :search_state, inclusion: { in: %w(public closed ready), allow_blank: true }
      validates :search_approver_state, inclusion: { in: %w(request approve), allow_blank: true }
      validates :search_released_start, datetime: true
      validates :search_released_close, datetime: true
      validates :search_updated_start, datetime: true
      validates :search_updated_close, datetime: true
    end

    def search
      @search ||= begin
        filename   = search_filename.present? ? { filename: /#{Regexp.escape(search_filename)}/i } : {}
        categories = search_category_ids.present? ? { category_ids: search_category_ids } : {}
        groups     = search_group_ids.present? ? { group_ids: search_group_ids } : {}
        state      = search_state.present? ? { state: search_state } : {}
        nodes      = build_search_nodes_criteria
        routes     = build_search_routes_criteria

        released = []
        released << { :released.gte => search_released_start } if search_released_start.present?
        released << { :released.lte => search_released_close } if search_released_close.present?

        updated = []
        updated << { :updated.gte => search_updated_start } if search_updated_start.present?
        updated << { :updated.lte => search_updated_close } if search_updated_close.present?

        approver = []
        case search_approver_state
        when 'request'
          approver << { workflow_user_id: @cur_user._id }
        when 'approve'
          approver << {
            workflow_state: "request",
            workflow_approvers: {
              "$elemMatch" => { "user_id" => @cur_user._id, "state" => "request" }
            }
          }
        end

        criteria = Cms::Page.site(@cur_site).
          allow(:read, @cur_user).
          search(name: search_name).
          where(filename).
          in(categories).
          in(groups).
          where(nodes).
          in(routes).
          where(state).
          and(released).
          and(updated).
          and(approver)
        @search_count = criteria.count
        criteria.order_by(filename: 1)
      end
    end

    def search_count
      search if @search_count.nil?
      @search_count
    end

    def search_state_options
      %w(public closed ready).map do |w|
        [ I18n.t("views.options.state.#{w}"), w ]
      end
    end

    def search_approver_state_options
      %w(request approve).map do |w|
        [ I18n.t("workflow.page.#{w}"), w ]
      end
    end

    def search_condition?
      normalize_search_routes
      self.class.fields.keys.any? do |k|
        k.start_with?("search_") && self[k].present?
      end
    end

    def brief_search_condition
      info = []

      [ :search_name_info, :search_filename_info, :search_category_ids_info, :search_group_ids_info,
        :search_node_ids, :search_routes_info, :search_released_info, :search_updated_info,
        :search_state_info, :search_approver_state_info ].each do |m|
        i = method(m).call
        info << i if i.present?
      end

      info.join(", ")
    end

    private
      def normalize_search_routes
        return if search_routes.blank?
        self.search_routes = search_routes.dup.select(&:present?)
      end

      def build_search_nodes_criteria
        if search_node_ids.present?
          { filename: /^#{search_nodes.map { |node| Regexp.escape("#{node.filename}/") }.join("|")}/ }
        else
          {}
        end
      end

      def build_search_routes_criteria
        normalize_search_routes
        search_routes.present? ? { route: search_routes } : {}
      end

      def search_name_info
        "#{Cms::Page.t(:name)}: #{search_name}" if search_name.present?
      end

      def search_filename_info
        "#{Cms::Page.t(:filename)}: #{search_filename}" if search_filename.present?
      end

      def search_category_ids_info
        "#{Cms::Page.t(:category_ids)}: #{search_categories.pluck(:name).join(",")}" if search_category_ids.present?
      end

      def search_group_ids_info
        "#{Cms::Page.t(:group_ids)}: #{search_groups.pluck(:name).join(",")}" if search_group_ids.present?
      end

      def search_node_ids_info
        "#{I18n.t 'cms.node'}: #{search_nodes.pluck(:name).join(",")}" if search_node_ids.present?
      end

      def search_routes_info
        normalize_search_routes
        if search_routes.present?
          "#{Cms::Page.t(:route)}: #{search_routes.map { |route| route_name(route) }.join(",")}"
        end
      end

      def route_name(route)
        "#{I18n.t("modules.#{route.sub(/\/.*/, '')}")}/#{I18n.t("mongoid.models.#{route}")}"
      end

      def search_released_info
        if search_released_start.present? || search_released_close.present?
          start = search_released_start.try(:strftime, "%Y/%m/%d %H:%M")
          close = search_released_close.try(:strftime, "%Y/%m/%d %H:%M")
          "#{Cms::Page.t(:released)}: #{start}-#{close}"
        end
      end

      def search_updated_info
        if search_updated_start.present? || search_updated_close.present?
          start = search_updated_start.try(:strftime, "%Y/%m/%d %H:%M")
          close = search_updated_close.try(:strftime, "%Y/%m/%d %H:%M")
          "#{Cms::Page.t(:updated)}: #{start}-#{close}"
        end
      end

      def search_state_info
        "#{Cms::Page.t(:state)}: #{I18n.t :"views.options.state.#{search_state}"}" if search_state.present?
      end

      def search_approver_state_info
        if search_approver_state.present?
          "#{Cms::Page.t(:workflow_state)}: #{I18n.t :"workflow.page.#{search_approver_state}"}"
        end
      end
  end
end
