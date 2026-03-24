class SS::Migration20260324000000
  include SS::Migration::Base

  def change
    # load all models
    ::Rails.application.eager_load!

    SS::User.unscoped.order_by(_id: 1).find_in_batches(batch_size: 20) do |users|
      users.each do |user|
        uid = user.organization_uid.to_s
        if uid.blank?
          type = nil
          sort_key = nil
        else
          type = uid.match?(/\A\d+\z/) ? 'numeric' : 'alpha'
          sort_key = uid.scan(/[a-zA-Z_\-\.]+|\d+/).map do |seg|
            seg.match?(/\A\d+\z/) ? seg.rjust(10, '0') : seg
          end.join
        end

        result = user.without_record_timestamps do
          user.set(
            organization_uid_type: type,
            organization_uid_sort_key: sort_key
          )
        end

        unless result
          warn "ユーザー #{user.name}(#{user.id}) でエラーが発生しました。"
          warn user.errors.full_messages.join("\n")
        end
      end
    end
  end
end
