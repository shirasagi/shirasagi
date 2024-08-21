## -------------------------------------

@site = Gws::Group.where(name: SS::Db::Seed.site_name).first
@site_name = SS::Db::Seed.site_name.sub("市", "")

# set initial settings
@site.attributes = {
  memo_quota: 100, memo_filesize_limit: 3
}
@site.save!

@users_hash = {}
def u(uid)
  @users_hash[uid.to_s] ||= begin
    user = Gws::User.find_by(uid: uid)
    user.cur_site = @site
    user
  end
end

@groups_hash = {}
def g(name)
  @groups_hash[name.to_s] ||= Gws::Group.site(@site).where(name: /\/#{Regexp.escape(name)}$/).first
end

@users = %w(sys admin user1 user2 user3 user4 user5).map { |uid| u(uid) }
@groups = Gws::Group.where(name: /^#{Regexp.escape(@site.name)}(\/|$)/)

@now = Time.zone.now
@today = Time.zone.today
@today_ym = @today.strftime('%Y-%m')

def new_ss_files(path, data)
  puts path

  file = Fs::UploadedFile.create_from_file(path)
  file.original_filename = data[:filename] if data[:filename].present?

  item = SS::File.new(data)
  item.in_file = file
  item.save!

  item
end

def create_item(model, data)
  puts data[:name]
  cond = { site_id: @site._id, name: data[:name] }
  item = model.find_or_initialize_by(cond)
  item.attributes = data
  item.cur_site ||= @site
  item.cur_user ||= u('admin') if item.respond_to?(:cur_user)
  if item.respond_to?("user_ids=")
    item.user_ids = (Array[item.user_ids].flatten.compact + [item.cur_user.id]).uniq
  end
  if item.respond_to?("group_ids=")
    item.group_ids = (Array[item.group_ids].flatten.compact + item.cur_user.group_ids).uniq
  end
  puts item.errors.full_messages unless item.save
  item
end

def create_column(type, data)
  case type
  when :text
    model = Gws::Column::TextField
  when :text_area
    model = Gws::Column::TextArea
  when :number
    model = Gws::Column::NumberField
  when :date
    model = Gws::Column::DateField
  when :url
    model = Gws::Column::UrlField
  when :checkbox
    model = Gws::Column::CheckBox
  when :radio
    model = Gws::Column::RadioButton
  when :select
    model = Gws::Column::Select
  when :file_upload
    model = Gws::Column::FileUpload
  end
  puts data[:name]
  cond = { site_id: @site._id, form_id: data[:form].id, name: data[:name] }
  item = model.find_or_initialize_by(cond)
  item.attributes = data.reverse_merge(cur_site: @site)
  puts item.errors.full_messages unless item.save
  item
end

## -------------------------------------

load "#{Rails.root}/db/seeds/gws/contents/custom_group.rb"
load "#{Rails.root}/db/seeds/gws/contents/notice.rb"
load "#{Rails.root}/db/seeds/gws/contents/link.rb"
load "#{Rails.root}/db/seeds/gws/contents/discussion.rb"
load "#{Rails.root}/db/seeds/gws/contents/facility.rb"
load "#{Rails.root}/db/seeds/gws/contents/memo.rb"
load "#{Rails.root}/db/seeds/gws/contents/schedule.rb"
load "#{Rails.root}/db/seeds/gws/contents/todo.rb"
load "#{Rails.root}/db/seeds/gws/contents/reminder.rb"
load "#{Rails.root}/db/seeds/gws/contents/board.rb"
load "#{Rails.root}/db/seeds/gws/contents/circular.rb"
load "#{Rails.root}/db/seeds/gws/contents/faq.rb"
load "#{Rails.root}/db/seeds/gws/contents/monitor.rb"
load "#{Rails.root}/db/seeds/gws/contents/qna.rb"
load "#{Rails.root}/db/seeds/gws/contents/report.rb"
load "#{Rails.root}/db/seeds/gws/contents/share.rb"
load "#{Rails.root}/db/seeds/gws/contents/user.rb"
load "#{Rails.root}/db/seeds/gws/contents/workflow.rb"
load "#{Rails.root}/db/seeds/gws/contents/bookmark.rb"
load "#{Rails.root}/db/seeds/gws/contents/max.rb"
load "#{Rails.root}/db/seeds/gws/contents/attendance.rb"
load "#{Rails.root}/db/seeds/gws/contents/affair.rb"
load "#{Rails.root}/db/seeds/gws/contents/daily_report.rb"
load "#{Rails.root}/db/seeds/gws/contents/presence.rb"
load "#{Rails.root}/db/seeds/gws/contents/survey.rb"
load "#{Rails.root}/db/seeds/gws/contents/contrast.rb"
load "#{Rails.root}/db/seeds/gws/contents/workload.rb"
load "#{Rails.root}/db/seeds/gws/contents/aggregation.rb"
load "#{Rails.root}/db/seeds/gws/contents/search_form.rb"
