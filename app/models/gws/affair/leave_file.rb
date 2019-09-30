class Gws::Affair::LeaveFile
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::File
  include Gws::Addon::Affair::FileTarget
  include Gws::Addon::Affair::Approver
  include Gws::Addon::Affair::LeaveFile
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
  include Gws::Affair::Searchable
  include Gws::Affair::AggregatePermission
  include SS::Release

  # rubocop:disable Style/ClassVars
  @@approver_user_class = Gws::User
  # rubocop:enable Style/ClassVars
  self.default_release_state = "closed"

  seqid :id
  field :name, type: String

  permit_params :name

  before_validation :validate_date
  before_validation :set_name

  validates :week_in_compensatory_file_id, presence: true, if: ->{ leave_type == "week_in_compensatory_leave" }
  validates :week_out_compensatory_file_id, presence: true, if: ->{ leave_type == "week_out_compensatory_leave" }
  validates :holiday_compensatory_file_id, presence: true, if: ->{ leave_type == "holiday_compensatory_leave" }
  validates :special_leave_id, presence: true, if: ->{ leave_type == "paidleave" }

  validate :validate_compensatory_file
  validate :validate_week_in_compensatory_file, if: ->{ week_in_compensatory_file }
  validate :validate_week_out_compensatory_file, if: ->{ week_out_compensatory_file }
  validate :validate_holiday_compensatory_file, if: ->{ holiday_compensatory_file }

  validates :name, length: { maximum: 80 }
  validates :leave_type, presence: true
  validates :start_at, presence: true, datetime: true
  validates :end_at, datetime: true

  after_destroy :reset_overtime_compensatory

  default_scope -> {
    order_by updated: -1
  }

  def private_show_path
    url_helper = Rails.application.routes.url_helpers
    url_helper.gws_affair_leave_file_path(id: id, site: site, state: 'all')
  end

  def workflow_wizard_path
    url_helper = Rails.application.routes.url_helpers
    url_helper.gws_affair_leave_wizard_path(site: site.id, id: id)
  end

  def workflow_pages_path
    url_helper = Rails.application.routes.url_helpers
    url_helper.gws_affair_leave_file_path(site: site.id, id: id, state: "all")
  end

  private

  def set_name
    self.name = term_label
  end
end
