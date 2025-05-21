class SS::ImageResize
  include SS::Model::ImageResize
  include Sys::Permission

  set_permission_name "sys_users", :edit

  class << self
    def effective_resize(user: nil, request_disable: false, **)
      return nil if request_disable && user && SS::ImageResize.allowed?(:disable, user.ss_user)

      criteria = SS::ImageResize.where(state: SS::ImageResize::STATE_ENABLED)
      all_ids = criteria.pluck(:id)
      return nil if all_ids.blank?

      ret = new
      all_ids.each_slice(20) do |ids|
        criteria.in(id: ids).to_a.each { ret = SS::ImageResize.intersection(ret, _1) }
      end

      ret
    end
  end
end
