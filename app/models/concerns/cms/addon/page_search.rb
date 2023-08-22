module Cms::Addon
  module PageSearchInfo
    extend ActiveSupport::Concern
    extend SS::Translation

    def brief_search_condition
      info = [
        :search_name_info, :search_filename_info, :search_category_ids_info, :search_group_ids_info,
        :search_node_ids_info, :search_layout_ids_info, :search_routes_info, :search_released_info, :search_updated_info, :search_approved_info,
        :search_state_info, :search_first_released_info, :search_approver_state_info ].map do |m|
        method(m).call
      end
      info.select(&:present?).join(", ")
    end

    def search_sort_options
      %w(name filename created updated_desc released_desc approved_desc).map do |k|
        [
          I18n.t("cms.sort_options.#{k}.title"),
          k.sub("_desc", " -1"),
          "data-description" => I18n.t("cms.sort_options.#{k}.description", default: nil)
        ]
      end
    end

    def search_state_options
      %w(public closed ready closing).map do |w|
        [ I18n.t("ss.options.state.#{w}"), w ]
      end
    end

    def search_first_released_options
      %w(draft published).map do |w|
        [ I18n.t("ss.options.first_released.#{w}"), w ]
      end
    end

    def search_approver_state_options
      %w(request approve remand).map do |w|
        [ I18n.t("workflow.page.#{w}"), w ]
      end
    end

    def status_options
      [
        [I18n.t('ss.options.state.public'), 'public'],
        [I18n.t('ss.options.state.closed'), 'closed'],
        [I18n.t('ss.options.state.ready'), 'ready'],
        [I18n.t('ss.options.state.request'), 'request'],
        [I18n.t('ss.options.state.remand'), 'remand'],
      ]
    end

    def search_date_options
      %w(absolute relative).map { |w| [ I18n.t("cms.options.search_date.#{w}"), w ] }
    end

    private

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

    def search_layout_ids_info
      "#{I18n.t 'cms.layout'}: #{search_layouts.pluck(:name).join(",")}" if search_layout_ids.present?
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
      if search_released_condition == 'absolute'
        if search_released_start.present? || search_released_close.present?
          start = search_released_start.try { |time| I18n.l(time, format: :picker) }
          close = search_released_close.try { |time| I18n.l(time, format: :picker) }
          "#{Cms::Page.t(:released)}: #{start}-#{close}"
        end
      elsif search_released_condition == 'relative' && search_released_after.present?
        return "#{Cms::Page.t(:released)}: #{search_released_after}#{I18n.t('ss.units.days_progress')}"
      end
    end

    def search_updated_info
      if search_updated_condition == 'absolute'
        if search_updated_start.present? || search_updated_close.present?
          start = search_updated_start.try { |time| I18n.l(time, format: :picker) }
          close = search_updated_close.try { |time| I18n.l(time, format: :picker) }
          "#{Cms::Page.t(:updated)}: #{start}-#{close}"
        end
      elsif search_updated_condition == 'relative' && search_updated_after.present?
        "#{Cms::Page.t(:updated)}: #{search_updated_after}#{I18n.t('ss.units.days_progress')}"
      end
    end

    def search_approved_info
      if search_approved_condition == 'absolute'
        if search_approved_start.present? || search_approved_close.present?
          start = search_approved_start.try { |time| I18n.l(time, format: :picker) }
          close = search_approved_close.try{ |time| I18n.l(time, format: :picker) }
          "#{Cms::Page.t(:approved)}: #{start}-#{close}"
        end
      elsif search_approved_condition == 'relative' && search_approved_after.present?
        "#{Cms::Page.t(:approved)}: #{search_approved_after}#{I18n.t('ss.units.days_progress')}"
      end
    end

    def search_state_info
      "#{Cms::Page.t(:state)}: #{I18n.t :"ss.options.state.#{search_state}"}" if search_state.present?
    end

    def search_first_released_info
      if search_first_released.present?
        "#{Cms::PageSearch.t(:search_first_released)}: #{I18n.t :"ss.options.state.#{search_first_released}"}"
      end
    end

    def search_approver_state_info
      if search_approver_state.present?
        "#{Cms::Page.t(:workflow_state)}: #{I18n.t :"workflow.page.#{search_approver_state}"}"
      end
    end
  end

  module PageSearch
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::PageSearchInfo

    KEYWORD_FIELDS = [
      :name, :html, :question, :upper_html, :lower_html, :contact_charge, :contact_tel,
      :contact_fax, :contact_email, :contact_link_url, :contact_link_name
    ].freeze

    COLUMN_VALUES_FIELDS = [
      :value, :text, :link_url, :link_label, :lists
    ].freeze

    included do
      field :search_name, type: String
      field :search_filename, type: String
      field :search_keyword, type: String
      field :search_state, type: String
      field :search_first_released, type: String
      field :search_approver_state, type: String
      field :search_released_condition, type: String
      field :search_released_start, type: DateTime
      field :search_released_close, type: DateTime
      field :search_released_after, type: Integer
      field :search_updated_condition, type: String
      field :search_updated_start, type: DateTime
      field :search_updated_close, type: DateTime
      field :search_updated_after, type: Integer
      field :search_approved_condition, type: String
      field :search_approved_start, type: DateTime
      field :search_approved_close, type: DateTime
      field :search_approved_after, type: Integer
      field :search_sort, type: String
      embeds_ids :search_categories, class_name: "Category::Node::Base"
      embeds_ids :search_groups, class_name: "SS::Group"
      embeds_ids :search_nodes, class_name: "Cms::Node"
      embeds_ids :search_layouts, class_name: "Cms::Layout"
      embeds_ids :search_users, class_name: "Cms::User"

      field :search_routes, type: SS::Extensions::Words, default: []

      permit_params :search_name, :search_filename, :search_keyword, :search_state, :search_approver_state
      permit_params :search_first_released, :search_sort
      permit_params :search_released_condition, :search_released_start, :search_released_close, :search_released_after
      permit_params :search_updated_condition, :search_updated_start, :search_updated_close, :search_updated_after
      permit_params :search_approved_condition, :search_approved_start, :search_approved_close, :search_approved_after
      permit_params search_category_ids: [], search_group_ids: [], search_node_ids: [],search_layout_ids: [], search_user_ids: [], search_routes: []

      before_validation :normalize_search_routes
      validates :search_state, inclusion: { in: %w(public closed ready closing), allow_blank: true }
      validates :search_approver_state, inclusion: { in: %w(request approve remand), allow_blank: true }
      validates :search_released_start, datetime: true
      validates :search_released_close, datetime: true
      validates :search_updated_start, datetime: true
      validates :search_updated_close, datetime: true
      validates :search_approved_start, datetime: true
      validates :search_approved_close, datetime: true
    end

    class Searcher
      private_class_method :new

      HANDLERS = %i[
        search_name search_filename search_nodes search_layouts search_keyword search_categories search_groups search_routes
        search_users search_state search_released search_updated search_approved search_approver search_first_released
        sort
      ].freeze

      def self.build_criteria(item, opts)
        searcher = new(item, opts)

        HANDLERS.each do |m|
          searcher.send(m)
        end

        searcher.to_criteria
      end

      def initialize(item, opts)
        @item = item
        @opts = opts
        @cur_site = @item.cur_site
        @cur_user = @item.cur_user
        @cur_date = Time.zone.now
        @criteria = Cms::Page.site(@cur_site).allow(:read, @cur_user)
      end

      def to_criteria
        @criteria.search(@opts)
      end

      def search_name
        return if @item.search_name.blank?

        @criteria = @criteria.where(name: /#{::Regexp.escape(@item.search_name)}/)
      end

      def search_filename
        return if @item.search_filename.blank?

        @criteria = @criteria.where(filename: /#{::Regexp.escape(@item.search_filename)}/)
      end

      def search_nodes
        return if @item.search_node_ids.blank?

        conds = @item.search_nodes.map { |node| ::Regexp.escape("#{node.filename}/") }
        return if conds.blank?

        @criteria = @criteria.where(filename: /^#{conds.join("|")}/)
      end

      def search_keyword
        return if @item.search_keyword.blank?

        conds = KEYWORD_FIELDS.map { |field| { field => /#{::Regexp.escape(@item.search_keyword)}/ } }
        conds << {
          column_values: {
            "$elemMatch" => {
              "$or"=> COLUMN_VALUES_FIELDS.map { |key| { key => { "$in" => [/#{::Regexp.escape(@item.search_keyword)}/] } } }
            }
          }
        }
        @criteria = @criteria.where("$and" => [{ "$or" => conds }])
      end

      def search_categories
        return if @item.search_category_ids.blank?
        @criteria = @criteria.in(category_ids: @item.search_category_ids)
      end

      def search_groups
        return if @item.search_group_ids.blank?

        @criteria = @criteria.in(group_ids: @item.search_group_ids)
      end

      def search_layouts
        return if @item.search_layout_ids.blank?
        @criteria =  @criteria.in(layout_id:  @item.search_layout_ids)
      end


      def search_routes
        return if @item.search_routes.blank?

        search_routes = @item.search_routes.dup.select(&:present?)
        return if search_routes.blank?

        @criteria = @criteria.in(route: search_routes)
      end

      def search_users
        return if @item.search_user_ids.blank?
        @criteria = @criteria.in(user_id: @item.search_user_ids)
      end

      def search_state
        return if @item.search_state.blank?

        if @item.search_state == "closing"
          @criteria = @criteria.where("$and" => [ { :state => "public" }, { :close_date.ne => nil } ])
        else
          @criteria = @criteria.where(state: @item.search_state)
        end
      end

      def search_released
        return if @item.search_released_condition.blank?

        released = []
        if @item.search_released_condition == 'absolute'
          released << { :released.gte => @item.search_released_start } if @item.search_released_start.present?
          released << { :released.lte => @item.search_released_close } if @item.search_released_close.present?
        elsif @item.search_released_condition == 'relative'
          released << { :released.lte => @cur_date - @item.search_released_after.days } if @item.search_released_after.present?
        end
        return if released.blank?

        @criteria = @criteria.where("$and" => released)
      end

      def search_updated
        return if @item.search_updated_condition.blank?

        updated = []
        if @item.search_updated_condition == 'absolute'
          updated << { :updated.gte => @item.search_updated_start } if @item.search_updated_start.present?
          updated << { :updated.lte => @item.search_updated_close } if @item.search_updated_close.present?
        elsif @item.search_updated_condition == 'relative'
          updated << { :updated.lte => @cur_date - @item.search_updated_after.days } if @item.search_updated_after.present?
        end
        return if updated.blank?

        @criteria = @criteria.where("$and" => updated)
      end

      def search_approved
        return if @item.search_approved_condition.blank?

        approved = []
        if @item.search_approved_condition == 'absolute'
          approved << { :approved.gte => @item.search_approved_start } if @item.search_approved_start.present?
          approved << { :approved.lte => @item.search_approved_close } if @item.search_approved_close.present?
        elsif @item.search_approved_condition == 'relative'
          approved << { :approved.lte => @cur_date - @item.search_approved_after.days } if @item.search_approved_after.present?
        end
        return if approved.blank?

        @criteria = @criteria.where("$and" => approved)
      end

      def search_approver
        return if @item.search_approver_state.blank?

        case @item.search_approver_state
        when 'request'
          @criteria = @criteria.where(workflow_state: "request", workflow_user_id: @cur_user.id)
        when 'approve'
          @criteria = @criteria.where(
            workflow_state: "request",
            workflow_approvers: {
              "$elemMatch" => { "user_id" => @cur_user.id, "state" => "request" }
            }
          )
        when 'remand'
          @criteria = @criteria.where(workflow_state: "remand", workflow_user_id: @cur_user.id)
        end
      end

      def search_first_released
        return if @item.search_first_released.blank?

        case @item.search_first_released
        when "draft"
          @criteria = @criteria.where(:first_released.exists => false)
        when "published"
          @criteria = @criteria.where(:first_released.exists => true)
        end
      end

      def sort
        if @item.search_sort.blank?
          @criteria = @criteria.reorder(filename: 1)
          return
        end

        h = {}
        @item.search_sort.split.each_slice(2) { |k, v| h[k] = (v == "-1") ? -1 : 1 }
        @criteria = @criteria.reorder(h)
      end
    end

    def search(opts = {})
      @search ||= begin
        criteria = Searcher.build_criteria(self, opts)
        @search_count = criteria.count
        criteria
      end
    end

    def search_count
      search if @search_count.nil?
      @search_count
    end

    def search_condition?
      normalize_search_routes
      self.class.fields.keys.any? do |k|
        k.start_with?("search_") && self[k].present?
      end
    end

    def enum_csv
      exporter = Cms::PageExporter.new(mode: "article", site: @cur_site, criteria: search)
      exporter.enum_csv(encoding: "Shift_JIS")
    end

    private

    def normalize_search_routes
      return if search_routes.blank?
      self.search_routes = search_routes.dup.select(&:present?)
    end
  end
end
