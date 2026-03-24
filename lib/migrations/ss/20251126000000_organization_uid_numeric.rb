class SS::Migration20251126000000
  include SS::Migration::Base

  def change
    # load all models
    ::Rails.application.eager_load!

    SS::User.unscoped.order_by(_id: 1).find_in_batches(batch_size: 20) do |users|
      users.each do |user|
        next if user.organization_uid.blank?

        organization_uid_numeric = user.organization_uid.to_s.to_i
        next if organization_uid_numeric == 0 && user.organization_uid.to_s != "0"

        begin
          user.without_record_timestamps do
            user.set(organization_uid_numeric: organization_uid_numeric)
          end
        rescue => e
          warn "ユーザー #{user.name}(#{user.id}) でエラーが発生しました。"
          warn e.message
        end
      end
    end
  end
end
