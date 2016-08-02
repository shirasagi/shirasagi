module Workflow::Addon
  module Approver
    extend ActiveSupport::Concern
    extend SS::Addon
    include Workflow::Approver
    include Workflow::MemberApprover
  end
end
