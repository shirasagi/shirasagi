class SS::Migration20240424000000
  include SS::Migration::Base

  depends_on "20240408000000"

  def change
    actions = %w(read edit delete release close)
    targets = %w(other private member)
    criteria = Cms::Role.all.unscoped
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(20) do |ids|
      criteria.in(id: ids).each do |role|
        permissions = role.permissions
        actions.each do |action|
          targets.each do |target|
            next if !role.permissions.include?("#{action}_#{target}_opendata_datasets")

            permissions << "#{action}_#{target}_opendata_resources"
          end
        end
        role.set(permissions: permissions)
      end
    end

    criteria = Opendata::Dataset.all
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(20) do |ids|
      criteria.in(id: ids).each do |dataset|
        dataset.resources.each do |resource|
          resource.set(group_ids: dataset.group_ids) if resource.groups.blank?
        end
        dataset.url_resources.each do |url_resource|
          url_resource.set(group_ids: dataset.group_ids) if url_resource.groups.blank?
        end
      end
    end
  end
end
