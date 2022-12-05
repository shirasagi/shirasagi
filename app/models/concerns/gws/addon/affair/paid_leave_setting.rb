module Gws::Addon::Affair::PaidLeaveSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  def paid_leave_files(opts = {})
    opts[:types] = %w(paidleave)
    leave_files(opts)
  end
end
