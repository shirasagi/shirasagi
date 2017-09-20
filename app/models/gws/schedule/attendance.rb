class Gws::Schedule::Attendance
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Reference::Schedule
  include Gws::Addon::GroupPermission

  set_permission_name 'gws_schedule_plans'

  attr_accessor :in_comment

  field :attendance_state, type: String

  validates :attendance_state, presence: true, inclusion: { in: %w(unknown attendance absence), allow_blank: true }
  validates :user_id, uniqueness: { scope: :schedule_id }
  after_save :post_comment

  permit_params :in_comment, :attendance_state

  def attendance_state_options
    %w(unknown attendance absence).map do |v|
      [ I18n.t("gws/schedule.options.attendance_state.#{v}"), v ]
    end
  end

  private

  def post_comment
    return if in_comment.blank?

    Gws::Schedule::Comment.create(
      cur_site: cur_site || self.site,
      cur_user: cur_user || self.user,
      cur_schedule: cur_schedule || self.schedule,
      text: in_comment,
      text_type: 'plain'
    )
  end
end
