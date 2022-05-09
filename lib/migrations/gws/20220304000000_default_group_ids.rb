class SS::Migration20220304000000
  include SS::Migration::Base

  depends_on "20211110000000"

  def change
    each_user do |user|
      default_group_ids = user.gws_default_group_ids
      default_group_ids = default_group_ids.to_a
      default_group_ids = default_group_ids.map { |key, value| [ key, value.to_i ] }
      default_group_ids = Hash[default_group_ids]
      user.set(gws_default_group_ids: default_group_ids)
    end
  end

  private

  def each_user(&block)
    criteria = Gws::User.all.unscoped.exists(gws_default_group_ids: true)
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(20) do |ids|
      criteria.in(id: ids).to_a.each(&block)
    end
  end
end
