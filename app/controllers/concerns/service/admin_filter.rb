module Service::AdminFilter
  extend ActiveSupport::Concern

  included do
    before_action :allow_only_admin
  end

  def allow_only_admin
    raise '403' unless @cur_user.admin?
  end
end
