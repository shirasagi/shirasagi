puts "# daily_report/form"

def create_daily_report_form(data)
  create_item(Gws::DailyReport::Form, data)
end

@wf_forms = [
  create_daily_report_form(
    name: '政策課', year: @site.fiscal_year, order: 10, memo: '政策課の日報です。', daily_report_group_id: g('政策課').id
  ),
  create_daily_report_form(
    name: '広報課', year: @site.fiscal_year, order: 20, memo: '広報課の日報です。', daily_report_group_id: g('広報課').id
  ),
  create_daily_report_form(
    name: '管理課', year: @site.fiscal_year, order: 30, memo: '管理課の日報です。', daily_report_group_id: g('管理課').id
  ),
  create_daily_report_form(
    name: '防災課', year: @site.fiscal_year, order: 40, memo: '防災課の日報です。', daily_report_group_id: g('防災課').id
  )
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

@wf_form1_cols = [
  create_column(:text_area, form: @wf_forms[1], name: 'その他業務', order: 10, required: 'optional'),
  create_column(:text_area, form: @wf_forms[1], name: '幹部会等', order: 20, required: 'optional'),
  create_column(:text_area, form: @wf_forms[1], name: 'プロジェクト関連', order: 30, required: 'optional'),
  create_column(:text_area, form: @wf_forms[1], name: '議会', order: 40, required: 'optional'),
  create_column(:text_area, form: @wf_forms[1], name: '人事・給与・共済', order: 50, required: 'optional'),
  create_column(:text_area, form: @wf_forms[1], name: '企画', order: 60, required: 'optional'),
  create_column(:text_area, form: @wf_forms[1], name: '財政', order: 70, required: 'optional')
]

@wf_form2_cols = [
  create_column(:text_area, form: @wf_forms[2], name: 'その他業務', order: 10, required: 'optional'),
  create_column(:text_area, form: @wf_forms[2], name: '幹部会等', order: 20, required: 'optional'),
  create_column(:text_area, form: @wf_forms[2], name: 'プロジェクト関連', order: 30, required: 'optional'),
  create_column(:text_area, form: @wf_forms[2], name: '議会', order: 40, required: 'optional'),
  create_column(:text_area, form: @wf_forms[2], name: '人事・給与・共済', order: 50, required: 'optional'),
  create_column(:text_area, form: @wf_forms[2], name: '企画', order: 60, required: 'optional'),
  create_column(:text_area, form: @wf_forms[2], name: '財政', order: 70, required: 'optional')
]

@wf_form3_cols = [
  create_column(:text_area, form: @wf_forms[3], name: 'その他業務', order: 10, required: 'optional'),
  create_column(:text_area, form: @wf_forms[3], name: '幹部会等', order: 20, required: 'optional'),
  create_column(:text_area, form: @wf_forms[3], name: 'プロジェクト関連', order: 30, required: 'optional'),
  create_column(:text_area, form: @wf_forms[3], name: '議会', order: 40, required: 'optional'),
  create_column(:text_area, form: @wf_forms[3], name: '人事・給与・共済', order: 50, required: 'optional'),
  create_column(:text_area, form: @wf_forms[3], name: '企画', order: 60, required: 'optional'),
  create_column(:text_area, form: @wf_forms[3], name: '財政', order: 70, required: 'optional')
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
  cur_user: u('user2'), cur_form: @wf_forms[2], name: u('user2').name,
  daily_report_date: Time.zone.today,
  column_values: [
    @wf_form2_cols[0].serialize_value('その他業務'),
    @wf_form2_cols[1].serialize_value(''),
    @wf_form2_cols[2].serialize_value(''),
    @wf_form2_cols[3].serialize_value(''),
    @wf_form2_cols[4].serialize_value(''),
    @wf_form2_cols[5].serialize_value(''),
    @wf_form2_cols[6].serialize_value('')
  ]
)

create_daily_report_report(
  cur_user: u('user3'), cur_form: @wf_forms[1], name: u('user3').name,
  daily_report_date: Time.zone.today,
  column_values: [
    @wf_form1_cols[0].serialize_value('その他業務'),
    @wf_form1_cols[1].serialize_value('幹部会等'),
    @wf_form1_cols[2].serialize_value(''),
    @wf_form1_cols[3].serialize_value(''),
    @wf_form1_cols[4].serialize_value(''),
    @wf_form1_cols[5].serialize_value(''),
    @wf_form1_cols[6].serialize_value('')
  ]
)

create_daily_report_report(
  cur_user: u('user3'), cur_form: @wf_forms[3], name: u('user3').name,
  daily_report_date: Time.zone.today,
  column_values: [
    @wf_form3_cols[0].serialize_value('その他業務'),
    @wf_form3_cols[1].serialize_value('幹部会等'),
    @wf_form3_cols[2].serialize_value(''),
    @wf_form3_cols[3].serialize_value(''),
    @wf_form3_cols[4].serialize_value(''),
    @wf_form3_cols[5].serialize_value(''),
    @wf_form3_cols[6].serialize_value('')
  ]
)

create_daily_report_report(
  cur_user: u('user4'), cur_form: @wf_forms[2], name: u('user4').name,
  daily_report_date: Time.zone.today, share_column_ids: [@wf_form2_cols[0].id],
  column_values: [
    @wf_form2_cols[0].serialize_value('その他業務'),
    @wf_form2_cols[1].serialize_value(''),
    @wf_form2_cols[2].serialize_value(''),
    @wf_form2_cols[3].serialize_value('議会'),
    @wf_form2_cols[4].serialize_value('人事・給与・共済'),
    @wf_form2_cols[5].serialize_value(''),
    @wf_form2_cols[6].serialize_value('')
  ]
)

create_daily_report_report(
  cur_user: u('user5'), cur_form: @wf_forms[1], name: u('user5').name,
  daily_report_date: Time.zone.today,
  column_values: [
    @wf_form1_cols[0].serialize_value('その他業務'),
    @wf_form1_cols[1].serialize_value(''),
    @wf_form1_cols[2].serialize_value(''),
    @wf_form1_cols[3].serialize_value(''),
    @wf_form1_cols[4].serialize_value(''),
    @wf_form1_cols[5].serialize_value(''),
    @wf_form1_cols[6].serialize_value('')
  ]
)
