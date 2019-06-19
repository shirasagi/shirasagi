puts "# survey/form"

def create_survey_form(data)
  create_item(Gws::Survey::Form, data)
end

@sv_forms = [
  create_survey_form(
    cur_site: @site, cur_user: u('admin'), name: '研修についてのアンケート', state: "public",
    due_date: Time.zone.now.change(hour: 15) + 90.days,
    contributor_model: "Gws::User", contributor_id: u('admin').id, contributor_name: u('admin').long_name,
    readable_setting_range: "public"
  )
]

@sv_form0_cols = [
  create_column(
    :radio, form: @sv_forms[0], name: '研修の内容は充実していましたか', order: 10, required: 'required',
    select_options: %w(満足 まあまあ満足 少し不満 不満)
  ),
  create_column(:text_area, form: @sv_forms[0], name: 'ご意見をお聞かせください。', order: 20, required: 'required'),
]
