module Cms::Addon
  module PageSearch
    extend ActiveSupport::Concern
    extend SS::Addon

    KEYWORD_FIELDS = [
      :name, :html, :question, :upper_html, :lower_html, :contact_charge, :contact_tel, :contact_fax, :contact_email
    ].freeze

    included do
      field :search_name, type: String
      field :search_filename, type: String
      field :search_keyword, type: String
      field :search_state, type: String
      field :search_first_released, type: String
      field :search_approver_state, type: String
      field :search_released_start, type: DateTime
      field :search_released_close, type: DateTime
      field :search_updated_start, type: DateTime
      field :search_updated_close, type: DateTime
      field :search_sort, type: String
      embeds_ids :search_categories, class_name: "Category::Node::Base"
      embeds_ids :search_groups, class_name: "SS::Group"
      embeds_ids :search_nodes, class_name: "Cms::Node"
      embeds_ids :search_users, class_name: "Cms::User"

      field :search_routes, type: SS::Extensions::Words, default: []

      permit_params :search_name, :search_filename, :search_keyword, :search_state, :search_approver_state
      permit_params :search_first_released, :search_sort
      permit_params :search_released_start, :search_released_close, :search_updated_start, :search_updated_close
      permit_params search_category_ids: [], search_group_ids: [], search_node_ids: [], search_user_ids: [], search_routes: []

      before_validation :normalize_search_routes
      validates :search_state, inclusion: { in: %w(public closed ready), allow_blank: true }
      validates :search_approver_state, inclusion: { in: %w(request approve remand), allow_blank: true }
      validates :search_released_start, datetime: true
      validates :search_released_close, datetime: true
      validates :search_updated_start, datetime: true
      validates :search_updated_close, datetime: true
    end

    def search(opts = {})
      @search ||= begin
        name       = search_name.present? ? { name: /#{Regexp.escape(search_name)}/ } : {}
        filename   = search_filename.present? ? { filename: /#{Regexp.escape(search_filename)}/ } : {}
        keyword    = build_search_keyword_criteria
        categories = search_category_ids.present? ? { category_ids: search_category_ids } : {}
        groups     = search_group_ids.present? ? { group_ids: search_group_ids } : {}
        users      = search_user_ids.present? ? { user_id: search_user_ids } : {}
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
          approver << {
            workflow_state: "request",
            workflow_user_id: @cur_user._id,
          }
        when 'approve'
          approver << {
            workflow_state: "request",
            workflow_approvers: {
              "$elemMatch" => { "user_id" => @cur_user._id, "state" => "request" }
            }
          }
        when 'remand'
          approver << {
            workflow_state: "remand",
            workflow_user_id: @cur_user._id,
          }
        end

        if search_first_released == "draft"
          first_released = { :first_released.exists => false }
        elsif search_first_released == "published"
          first_released = { :first_released.exists => true }
        else
          first_released = {}
        end

        criteria = Cms::Page.site(@cur_site).
          allow(:read, @cur_user).
          where(name).
          where(filename).
          where(nodes).
          and(keyword).
          in(categories).
          in(groups).
          in(routes).
          in(users).
          where(state).
          and(released).
          and(updated).
          and(approver).
          and(first_released).
          search(opts)

        @search_count = criteria.count
        criteria.order_by(search_sort_hash)
      end
    end

    def status_options
      [
        [I18n.t('views.options.state.public'), 'public'],
        [I18n.t('views.options.state.closed'), 'closed'],
        [I18n.t('views.options.state.ready'), 'ready'],
        [I18n.t('views.options.state.request'), 'request'],
        [I18n.t('views.options.state.remand'), 'remand'],
      ]
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

    def search_first_released_options
      %w(draft published).map do |w|
        [ I18n.t("views.options.first_released.#{w}"), w ]
      end
    end

    def search_approver_state_options
      %w(request approve remand).map do |w|
        [ I18n.t("workflow.page.#{w}"), w ]
      end
    end

    def search_condition?
      normalize_search_routes
      self.class.fields.keys.any? do |k|
        k.start_with?("search_") && self[k].present?
      end
    end

    def search_sort_options
      [
        [I18n.t('cms.options.sort.filename'), 'filename'],
        [I18n.t('cms.options.sort.name'), 'name'],
        [I18n.t('cms.options.sort.created'), 'created'],
        [I18n.t('cms.options.sort.updated_1'), 'updated -1'],
        [I18n.t('cms.options.sort.released_1'), 'released -1'],
      ]
    end

    def search_sort_hash
      return { filename: 1 } if search_sort.blank?
      h = {}
      search_sort.split(" ").each_slice(2) { |k, v| h[k] = (v =~ /-1$/ ? -1 : 1) }
      h
    end

    def brief_search_condition
      info = [
        :search_name_info, :search_filename_info, :search_category_ids_info, :search_group_ids_info,
        :search_node_ids_info, :search_routes_info, :search_released_info, :search_updated_info,
        :search_state_info, :search_first_released_info, :search_approver_state_info ].map do |m|
        method(m).call
      end
      info.select(&:present?).join(", ")
    end

    private
      def normalize_search_routes
        return if search_routes.blank?
        self.search_routes = search_routes.dup.select(&:present?)
      end

      def build_search_keyword_criteria
        if search_keyword.present?
          { "$or" => KEYWORD_FIELDS.map { |field| { field => /#{Regexp.escape(search_keyword)}/ } } }
        else
          {}
        end
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

      def search_first_released_info
        if search_first_released.present?
          "#{Cms::PageSearch.t(:search_first_released)}: #{I18n.t :"views.options.state.#{search_first_released}"}"
        end
      end

      def search_approver_state_info
        if search_approver_state.present?
          "#{Cms::Page.t(:workflow_state)}: #{I18n.t :"workflow.page.#{search_approver_state}"}"
        end
      end
  end
end
