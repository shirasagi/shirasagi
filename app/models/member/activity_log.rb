class Member::ActivityLog
  include SS::Document
  include SS::Reference::Site
  include Cms::Reference::Member

  seqid :id
  field :activity_type, type: String
  field :remote_addr, type: String
  field :user_agent, type: String

  index({ site_id: 1, member_id: 1, activity_type: 1 })
  index({ updated: -1 })
end
