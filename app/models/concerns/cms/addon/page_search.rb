module Cms::Addon
  module PageSearchInfo
    extend ActiveSupport::Concern
    extend SS::Translation

    def brief_search_condition
      info = [
        :search_name_info, :search_filename_info, :search_category_ids_info, :search_group_ids_info,
        :search_node_ids_info, :search_routes_info, :search_released_info, :search_updated_info, :search_approved_info,
        :search_state_info, :search_first_released_info, :search_approver_state_info ].map do |m|
        method(m).call
      end
      info.select(&:present?).join(", ")
    end

    def search_sort_options
      [
        [I18n.t('cms.options.sort.filename'), 'filename'],
        [I18n.t('cms.options.sort.name'), 'name'],
        [I18n.t('cms.options.sort.created'), 'created'],
        [I18n.t('cms.options.sort.updated_1'), 'updated -1'],
        [I18n.t('cms.options.sort.released_1'), 'released -1'],
        [I18n.t('cms.options.sort.approved_1'), 'approved -1']
      ]
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
          start = search_released_start.try(:strftime, "%Y/%m/%d %H:%M")
          close = search_released_close.try(:strftime, "%Y/%m/%d %H:%M")
          "#{Cms::Page.t(:released)}: #{start}-#{close}"
        end
      elsif search_released_condition == 'relative' && search_released_after.present?
        return "#{Cms::Page.t(:released)}: #{search_released_after}#{I18n.t('ss.units.days_progress')}"
      end
    end

    def search_updated_info
      if search_updated_condition == 'absolute'
        if search_updated_start.present? || search_updated_close.present?
          start = search_updated_start.try(:strftime, "%Y/%m/%d %H:%M")
          close = search_updated_close.try(:strftime, "%Y/%m/%d %H:%M")
          "#{Cms::Page.t(:updated)}: #{start}-#{close}"
        end
      elsif search_updated_condition == 'relative' && search_updated_after.present?
        "#{Cms::Page.t(:updated)}: #{search_updated_after}#{I18n.t('ss.units.days_progress')}"
      end
    end

    def search_approved_info
      if search_approved_condition == 'absolute'
        if search_approved_start.present? || search_approved_close.present?
          start = search_approved_start.try(:strftime, "%Y/%m/%d %H:%M")
          close = search_approved_close.try(:strftime, "%Y/%m/%d %H:%M")
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
      embeds_ids :search_users, class_name: "Cms::User"

      field :search_routes, type: SS::Extensions::Words, default: []

      permit_params :search_name, :search_filename, :search_keyword, :search_state, :search_approver_state
      permit_params :search_first_released, :search_sort
      permit_params :search_released_condition, :search_released_start, :search_released_close, :search_released_after
      permit_params :search_updated_condition, :search_updated_start, :search_updated_close, :search_updated_after
      permit_params :search_approved_condition, :search_approved_start, :search_approved_close, :search_approved_after
      permit_params search_category_ids: [], search_group_ids: [], search_node_ids: [], search_user_ids: [], search_routes: []

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

    def search(opts = {})
      @search ||= begin
        cur_date = Time.zone.now

        name           = search_name.present? ? { name: /#{::Regexp.escape(search_name)}/ } : {}
        filename       = search_filename.present? ? { filename: /#{::Regexp.escape(search_filename)}/ } : {}
        keyword        = build_search_keyword_criteria
        categories     = search_category_ids.present? ? { category_ids: search_category_ids } : {}
        groups         = search_group_ids.present? ? { group_ids: search_group_ids } : {}
        users          = search_user_ids.present? ? { user_id: search_user_ids } : {}
        state          = build_search_state_criteria
        nodes          = build_search_nodes_criteria
        routes         = build_search_routes_criteria
        approver       = build_search_approver_criteria
        first_released = build_search_first_released_criteria

        released = []
        if search_released_condition == 'absolute'
          released << { :released.gte => search_released_start } if search_released_start.present?
          released << { :released.lte => search_released_close } if search_released_close.present?
        elsif search_released_condition == 'relative'
          released << { :released.lte => cur_date - search_released_after.days } if search_released_after.present?
        end

        updated = []
        if search_updated_condition == 'absolute'
          updated << { :updated.gte => search_updated_start } if search_updated_start.present?
          updated << { :updated.lte => search_updated_close } if search_updated_close.present?
        elsif search_updated_condition == 'relative'
          updated << { :updated.lte => cur_date - search_updated_after.days } if search_updated_after.present?
        end

        approved = []
        if search_approved_condition == 'absolute'
          approved << { :approved.gte => search_approved_start } if search_approved_start.present?
          approved << { :approved.lte => search_approved_close } if search_approved_close.present?
        elsif search_approved_condition == 'relative'
          approved << { :approved.lte => cur_date - search_approved_after.days } if search_approved_after.present?
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
          and(state).
          and(released).
          and(updated).
          and(approved).
          and(approver).
          and(first_released).
          search(opts)

        @search_count = criteria.count
        criteria.order_by(search_sort_hash)
      end
    end

    def search_sort_hash
      return { filename: 1 } if search_sort.blank?
      h = {}
      search_sort.split(" ").each_slice(2) { |k, v| h[k] = (v =~ /-1$/ ? -1 : 1) }
      h
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
      Enumerator.new do |y|
        y << encode_sjis(headers.to_csv)
        search.each do |content|
          content.site ||= @cur_site
          y << encode_sjis(row(content).to_csv)
        end
      end
    end

    private

    def normalize_search_routes
      return if search_routes.blank?
      self.search_routes = search_routes.dup.select(&:present?)
    end

    def build_search_state_criteria
      return {} unless search_state.present?

      if search_state == "closing"
        { "$and" => [ { :state => "public" }, { :close_date.ne => nil } ] }
      else
        { state: search_state }
      end
    end

    def build_search_keyword_criteria
      if search_keyword.present?
        { "$or" => KEYWORD_FIELDS.map { |field| { field => /#{::Regexp.escape(search_keyword)}/ } } }
      else
        {}
      end
    end

    def build_search_nodes_criteria
      if search_node_ids.present?
        { filename: /^#{search_nodes.map { |node| ::Regexp.escape("#{node.filename}/") }.join("|")}/ }
      else
        {}
      end
    end

    def build_search_routes_criteria
      normalize_search_routes
      search_routes.present? ? { route: search_routes } : {}
    end

    def build_search_approver_criteria
      case search_approver_state
      when 'request'
        {
          workflow_state: "request",
          workflow_user_id: @cur_user._id,
        }
      when 'approve'
        {
          workflow_state: "request",
          workflow_approvers: {
            "$elemMatch" => { "user_id" => @cur_user._id, "state" => "request" }
          }
        }
      when 'remand'
        {
          workflow_state: "remand",
          workflow_user_id: @cur_user._id,
        }
      else
        {}
      end
    end

    def build_search_first_released_criteria
      case search_first_released
      when "draft"
        { :first_released.exists => false }
      when "published"
        { :first_released.exists => true }
      else
        {}
      end
    end

    def encode_sjis(str)
      str.encode("SJIS", invalid: :replace, undef: :replace)
    end

    def category_name_tree(item)
      id_list = item.categories.pluck(:id)

      ct_list = []
      id_list.each do |id|
        name_list = []
        filename_str = []
        filename_array = Cms::Node.where(_id: id).pluck(:filename).first.split(/\//)
        filename_array.each do |filename|
          filename_str << filename
          name_list << Cms::Node.where(filename: filename_str.join("/")).pluck(:name).first
        end
        ct_list << name_list.join("/")
      end
      ct_list
    end

    def headers
      %w(
        filename name index_name layout body_layout_id order
        keywords description summary_html
        html body_part
        categories
        event_name event_dates
        related_pages
        parent_crumb
        contact_state contact_group contact_charge contact_tel contact_fax contact_email contact_link_url contact_link_name
        released release_date close_date
        groups permission_level
        state
      ).map { |e| Cms::Page.t e }
    end

    def row(item)
      [
        # basic
        item.basename,
        item.name,
        item.index_name,
        Cms::Layout.where(_id: item.layout_id).pluck(:name).first,
        Cms::BodyLayout.where(_id: item.body_layout_id).pluck(:name).first,
        item.order,

        # meta
        item.keywords,
        item.description,
        item.summary_html,

        item.html,
        item.body_parts.map{ |body| body.gsub("\t", '    ') }.join("\t"),

        # category
        category_name_tree(item).join("\n"),

        # event
        item.event_name,
        item.event_dates,

        # related pages
        item.related_pages.pluck(:filename).join("\n"),

        # crumb
        item.parent_crumb_urls,

        # contact
        item.label(:contact_state),
        item.contact_group.try(:name),
        item.contact_charge,
        item.contact_tel,
        item.contact_fax,
        item.contact_email,
        item.contact_link_url,
        item.contact_link_name,

        # released
        item.released.try(:strftime, "%Y/%m/%d %H:%M"),
        item.release_date.try(:strftime, "%Y/%m/%d %H:%M"),
        item.close_date.try(:strftime, "%Y/%m/%d %H:%M"),

        # groups
        item.groups.pluck(:name).join("\n"),
        item.permission_level,

        # state
        item.label(:state)
      ]
    end
  end
end
