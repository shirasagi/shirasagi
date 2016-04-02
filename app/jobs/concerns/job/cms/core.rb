module Job::Cms::Core
  extend ActiveSupport::Concern
  include Job::SS::Core

  def bind(bindings)
    self.site_id = bindings['site_id'].to_param
    self.group_id = bindings['group_id'].to_param
    self.user_id = bindings['user_id'].to_param
    self.node_id = bindings['node_id'].to_param
    self.member_id = bindings['member_id'].to_param
    self
  end

  private

  def serialize_bindings
    bindings = []
    bindings << [ 'site_id', site_id ] if site_id.present?
    bindings << [ 'node_id', node_id ] if node_id.present?
    bindings << [ 'group_id', group_id ] if group_id.present?
    bindings << [ 'user_id', user_id ] if user_id.present?
    bindings << [ 'member_id', member_id ] if member_id.present?
    bindings = Hash[bindings]
    bindings = [ bindings ]
    ActiveJob::Arguments.serialize(bindings)
  end
end
