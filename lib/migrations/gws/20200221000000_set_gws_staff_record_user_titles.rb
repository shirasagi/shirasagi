class SS::Migration20200221000000
  include SS::Migration::Base

  depends_on "20191029000001"

  def change
    model = Gws::StaffRecord::User
    all_ids = model.pluck(:id)
    all_ids.each_slice(20) do |ids|
      model.in(id: ids).each do |user|
        next if user.title_ids.present?

        title_name = user[:title_name]

        next if title_name.blank?

        sr_user_title = user.year.yearly_user_titles.find_or_initialize_by(name: title_name)
        if sr_user_title.new_record?
          user_title = Gws::UserTitle.site(user.year.site).active.where(name: title_name).first

          next if user_title.blank?

          sr_user_title.cur_site = user.year.site
          sr_user_title.code = user_title.code
          sr_user_title.order = user_title.order
          # sr_user_title.activation_date = user_title.activation_date
          # sr_user_title.expiration_date = user_title.expiration_date
          sr_user_title.remark = user_title.remark
          sr_user_title.save
        end
        if sr_user_title.active?
          user.title_ids = [sr_user_title.id]
          user.save
        end
      end
    end
  end
end
