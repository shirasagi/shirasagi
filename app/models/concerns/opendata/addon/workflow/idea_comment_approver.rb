module Opendata::Addon::Workflow
  module IdeaCommentApprover
    extend ActiveSupport::Concern
    extend SS::Addon
    include Workflow::Approver
    include Workflow::MemberApprover
  end
end
