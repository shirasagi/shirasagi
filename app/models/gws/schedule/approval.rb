class Gws::Schedule::Approval
  include SS::Document
  include Gws::Reference::User

  embedded_in :schedule, inverse_of: :approvals
  field :approval_state, type: String
  belongs_to :facility, class_name: 'Gws::Facility::Item'

  permit_params :approval_state, :facility_id

  validates :approval_state, presence: true, inclusion: { in: %w(unknown approve deny), allow_blank: true }
  validates :user_id, uniqueness: { scope: [ :schedule_id, :facility_id ] }

  def approval_state_options
    %w(unknown approve deny).map do |v|
      [ I18n.t("gws/schedule.options.approval_state.#{v}"), v ]
    end
  end

  delegate :subscribed_users, to: :_parent
end
