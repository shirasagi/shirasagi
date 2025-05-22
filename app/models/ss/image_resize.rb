class SS::ImageResize
  include SS::Model::ImageResize
  include Sys::Permission

  set_permission_name "sys_users", :edit

  class << self
    def current_resize
      criteria = SS::ImageResize.where(state: SS::ImageResize::STATE_ENABLED)
      criteria = criteria.only(:max_width, :max_height, :size, :quality, :updated)
      all_ids = criteria.pluck(:id)
      return nil if all_ids.blank?

      cache_keys = [
        self.collection_name, "current", SS.version, all_ids.length, criteria.max(:updated).to_i
      ]
      Rails.cache.fetch(cache_keys.join("_")) do
        ret = new
        all_ids.each_slice(20) do |ids|
          criteria.in(id: ids).to_a.each { ret = SS::ImageResize.intersection(ret, _1) }
        end
        ret
      end
    end

    def effective_resize(user:, request_disable: false, **)
      return nil if request_disable && user && SS::ImageResize.allowed?(:disable, user.ss_user)
      current_resize
    end
  end
end
