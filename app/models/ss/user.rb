class SS::User
  include SS::Model::User
  include SS::Reference::UserTitles
  include SS::Reference::UserOccupations
  include Sys::Addon::Role
  include Sys::Reference::Role
  include Sys::Permission

  set_permission_name "sys_users", :edit

  require 'csv'

  def self.to_csv
    I18n.with_locale(I18n.default_locale) do
      CSV.generate(headers: true) do |csv|
        # ヘッダー（カラム名）の設定
        columns = %w(id name email last_loggedin created updated)
        csv << columns.map { |k| I18n.t("ss.model.user.#{k}") }

        all.each do |user|
          csv << [
            user.id,
            user.name,
            user.email,
            user.last_loggedin.try { |time| I18n.l(time, format: :picker) },
            I18n.l(user.created, format: :picker),
            I18n.l(user.updated, format: :picker)
          ]
        end
      end
    end
  end

end
