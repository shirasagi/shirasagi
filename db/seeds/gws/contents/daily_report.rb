puts "# daily_report/form"

def create_daily_report_form(data)
  create_item(Gws::DailyReport::Form, data)
end

@wf_forms = [
  create_daily_report_form(name: '総務課', order: 10, state: 'public', memo: '総務課の日報です。')
]

@wf_form0_cols = [
  create_column(:text_area, form: @wf_forms[0], name: 'その他業務', order: 10, required: 'optional'),
  create_column(:text_area, form: @wf_forms[0], name: '幹部会等', order: 20, required: 'optional'),
  create_column(:text_area, form: @wf_forms[0], name: 'プロジェクト関連', order: 30, required: 'optional'),
  create_column(:text_area, form: @wf_forms[0], name: '議会', order: 40, required: 'optional'),
  create_column(:text_area, form: @wf_forms[0], name: '人事・給与・共済', order: 50, required: 'optional'),
  create_column(:text_area, form: @wf_forms[0], name: '企画', order: 60, required: 'optional'),
  create_column(:text_area, form: @wf_forms[0], name: '財政', order: 70, required: 'optional')
]

## -------------------------------------
puts "# daily_report/report"

def create_daily_report_report(data)
  create_item(Gws::DailyReport::Report, data)
end

create_daily_report_report(
  cur_user: u('user1'), cur_form: @wf_forms[0], name: u('user1').name,
  daily_report_date: Time.zone.today,
  column_values: [
    @wf_form0_cols[0].serialize_value('その他業務'),
    @wf_form0_cols[1].serialize_value('幹部会等'),
    @wf_form0_cols[2].serialize_value('プロジェクト関連'),
    @wf_form0_cols[3].serialize_value('議会'),
    @wf_form0_cols[4].serialize_value(''),
    @wf_form0_cols[5].serialize_value(''),
    @wf_form0_cols[6].serialize_value('')
  ]
)

create_daily_report_report(
  cur_user: u('user2'), cur_form: @wf_forms[0], name: u('user2').name,
  daily_report_date: Time.zone.today,
  column_values: [
    @wf_form0_cols[0].serialize_value('その他業務'),
    @wf_form0_cols[1].serialize_value(''),
    @wf_form0_cols[2].serialize_value(''),
    @wf_form0_cols[3].serialize_value(''),
    @wf_form0_cols[4].serialize_value(''),
    @wf_form0_cols[5].serialize_value(''),
    @wf_form0_cols[6].serialize_value('')
  ]
)

create_daily_report_report(
  cur_user: u('user3'), cur_form: @wf_forms[0], name: u('user3').name,
  daily_report_date: Time.zone.today,
  column_values: [
    @wf_form0_cols[0].serialize_value('その他業務'),
    @wf_form0_cols[1].serialize_value('幹部会等'),
    @wf_form0_cols[2].serialize_value(''),
    @wf_form0_cols[3].serialize_value(''),
    @wf_form0_cols[4].serialize_value(''),
    @wf_form0_cols[5].serialize_value(''),
    @wf_form0_cols[6].serialize_value('')
  ]
)

create_daily_report_report(
  cur_user: u('user4'), cur_form: @wf_forms[0], name: u('user4').name,
  daily_report_date: Time.zone.today, share_column_ids: [@wf_form0_cols[0].id],
  column_values: [
    @wf_form0_cols[0].serialize_value('その他業務'),
    @wf_form0_cols[1].serialize_value(''),
    @wf_form0_cols[2].serialize_value(''),
    @wf_form0_cols[3].serialize_value('議会'),
    @wf_form0_cols[4].serialize_value('人事・給与・共済'),
    @wf_form0_cols[5].serialize_value(''),
    @wf_form0_cols[6].serialize_value('')
  ]
)

create_daily_report_report(
  cur_user: u('user5'), cur_form: @wf_forms[0], name: u('user5').name,
  daily_report_date: Time.zone.today,
  column_values: [
    @wf_form0_cols[0].serialize_value('その他業務'),
    @wf_form0_cols[1].serialize_value(''),
    @wf_form0_cols[2].serialize_value(''),
    @wf_form0_cols[3].serialize_value(''),
    @wf_form0_cols[4].serialize_value(''),
    @wf_form0_cols[5].serialize_value(''),
    @wf_form0_cols[6].serialize_value('')
  ]
)
