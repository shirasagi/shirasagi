class Cms::PageSearch
  include SS::Document
  include SS::Reference::Site
  include Cms::Addon::GroupPermission

  attr_accessor :cur_user

  seqid :id
  field :name, type: String
  field :order, type: Integer, default: 0

  field :search_name, type: String
  field :search_filename, type: String
  field :search_state, type: String
  field :search_approver_state, type: String
  field :search_released_start, type: DateTime
  field :search_released_close, type: DateTime
  field :search_updated_start, type: DateTime
  field :search_updated_close, type: DateTime
  embeds_ids :search_categories, class_name: "Category::Node::Base"
  embeds_ids :search_groups, class_name: "SS::Group"

  permit_params :name, :order
  permit_params :search_name, :search_filename, :search_state, :search_approver_state
  permit_params :search_released_start, :search_released_close, :search_updated_start, :search_updated_close
  permit_params search_category_ids: [], search_group_ids: []

  validates :name, presence: true
  validates :search_state, inclusion: { in: %w(public closed ready), allow_blank: true }
  validates :search_approver_state, inclusion: { in: %w(request approve), allow_blank: true }
  validates :search_released_start, datetime: true
  validates :search_released_close, datetime: true
  validates :search_updated_start, datetime: true
  validates :search_updated_close, datetime: true

  class << self
    def search(params)
      criteria = self.where({})
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name, :search_name, :search_filename
      end
      criteria
    end
  end

  def search
    @search ||= begin
      filename   = search_filename.present? ? { filename: /#{Regexp.escape(search_filename)}/i } : {}
      categories = search_category_ids.present? ? { category_ids: search_category_ids } : {}
      groups     = search_group_ids.present? ? { group_ids: search_group_ids } : {}
      state      = search_state.present? ? { state: search_state } : {}

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
    self.class.fields.keys.any? do |k|
      k.start_with?("search_") && self[k].present?
    end
  end

  def brief_search_condition
    info = []

    info << "#{Cms::Page.t(:name)}: #{search_name}" if search_name.present?
    info << "#{Cms::Page.t(:filename)}: #{search_filename}" if search_filename.present?
    info << "#{Cms::Page.t(:category_ids)}: #{search_categories.pluck(:name).join(",")}" if search_category_ids.present?
    info << "#{Cms::Page.t(:group_ids)}: #{search_groups.pluck(:name).join(",")}" if search_group_ids.present?
    if search_released_start.present? || search_released_close.present?
      start = search_released_start.try(:strftime, "%Y/%m/%d %H:%M")
      close = search_released_close.try(:strftime, "%Y/%m/%d %H:%M")
      info << "#{Cms::Page.t(:released)}: #{start}-#{close}"
    end
    if search_updated_start.present? || search_updated_close.present?
      start = search_updated_start.try(:strftime, "%Y/%m/%d %H:%M")
      close = search_updated_close.try(:strftime, "%Y/%m/%d %H:%M")
      info << "#{Cms::Page.t(:updated)}: #{start}-#{close}"
    end
    info << "#{Cms::Page.t(:state)}: #{I18n.t :"views.options.state.#{search_state}"}" if search_state.present?
    if search_approver_state.present?
      info << "#{Cms::Page.t(:workflow_state)}: #{I18n.t :"workflow.page.#{search_approver_state}"}"
    end

    info.join(", ")
  end
end
