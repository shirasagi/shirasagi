class Gws::Affair::OvertimeFile
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::Affair::Capital
  include Gws::Addon::Affair::FileTarget
  include Gws::Addon::Affair::OvertimeResult
  include Gws::Addon::Affair::OvertimeDayResult
  include Gws::Addon::Affair::Approver
  include Gws::Addon::Affair::OvertimeFile
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

  default_scope -> { order_by updated: -1 }

  def status
    if result_closed?
      'result_closed'
    elsif state == 'approve'
      'approve'
    elsif workflow_state == 'cancelled'
      'draft'
    elsif workflow_state.present?
      workflow_state
    elsif state == 'closed'
      'draft'
    else
      state
    end
  end

  def status_options
    I18n.t("gws/affair.options.overtime_status").map { |k, v| [v, k] }
  end

  def private_show_path
    url_helper = Rails.application.routes.url_helpers
    url_helper.gws_affair_overtime_file_path(id: id, site: site, state: 'all')
  end

  def workflow_wizard_path
    url_helper = Rails.application.routes.url_helpers
    url_helper.gws_affair_overtime_wizard_path(site: site.id, id: id)
  end

  def workflow_pages_path
    url_helper = Rails.application.routes.url_helpers
    url_helper.gws_affair_overtime_file_path(site: site.id, id: id, state: "all")
  end
end
