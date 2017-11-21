module Gws::Memo::GroupSetting
  extend ActiveSupport::Concern
  extend Gws::GroupSetting

  included do
    field :memo_filesize_limit, type: Integer

    permit_params :memo_filesize_limit
  end

  def memo_filesize_limit
    self[:memo_filesize_limit]
  end

  class << self
    def allowed?(action, user, opts = {})
      Gws::Memo::Signature.allowed?(action, user, opts)
    end
  end

end
