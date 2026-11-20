require 'spec_helper'

describe 'article_pages', type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:group) { cms_group }
  let!(:user) { cms_user }
  let!(:node) { create :article_node_page, cur_site: site, group_ids: [ group.id ] }
  let!(:form) { create :cms_form, cur_site: site, state: 'public', sub_type: 'entry' }

  let!(:node2) { create :article_node_page, cur_site: site, group_ids: [ group.id ] }
  let!(:selectable_page4) { create :article_page, cur_site: site, cur_node: node2, state: "closed" }

  let!(:column1) do
    create(:cms_column_text_field, cur_site: site, cur_form: form, required: "optional", order: 1, input_type: 'text')
  end
  let!(:column2) do
    create(:cms_column_date_field, cur_site: site, cur_form: form, required: "optional", order: 2)
  end
  let!(:column3) do
    create(:cms_column_url_field2, cur_site: site, cur_form: form, required: "optional", order: 3, html_tag: '')
  end
  let!(:column4) do
    create(:cms_column_text_area, cur_site: site, cur_form: form, required: "optional", order: 4)
  end
  let!(:column5) do
    create(:cms_column_select, cur_site: site, cur_form: form, required: "optional", order: 5)
  end
  let!(:column6) do
    create(:cms_column_radio_button, cur_site: site, cur_form: form, required: "optional", order: 6)
  end
  let!(:column7) do
    create(:cms_column_check_box, cur_site: site, cur_form: form, required: "optional", order: 7)
  end
  let!(:column8) do
    create(:cms_column_file_upload, cur_site: site, cur_form: form, required: "optional", order: 8, file_type: "image")
  end
  let!(:column9) do
    create(:cms_column_free, cur_site: site, cur_form: form, required: "optional", order: 9)
  end
  let!(:column10) do
    create(:cms_column_headline, cur_site: site, cur_form: form, required: "optional", order: 10)
  end
  let!(:column11) do
    create(:cms_column_list, cur_site: site, cur_form: form, required: "optional", order: 11)
  end
  let!(:column12) do
    create(:cms_column_table, cur_site: site, cur_form: form, required: "optional", order: 12)
  end
  let!(:column13) do
    create(:cms_column_youtube, cur_site: site, cur_form: form, required: "optional", order: 13)
  end
  let!(:column14) do
    create(:cms_column_select_page, cur_site: site, cur_form: form, required: "optional", order: 14, node_ids: [node2.id])
  end
  let(:name) { unique_id }
  let(:column1_value1) { unique_id }
  let(:column2_value1) { "#{rand(2000..2050)}/01/01" }
  let(:column3_label1) { unique_id }
  let(:column3_url1) { "http://#{site.domain}/#{unique_id}/" }
  let(:column3_target1) { [ "", "_blank" ].sample }
  let(:column4_value1) { "#{unique_id}#{unique_id}\n#{unique_id}#{unique_id}#{unique_id}" }
  let(:column5_value1) { column5.select_options.sample }
  let(:column6_value1) { column6.select_options.sample }
  let(:column7_value1) { column7.select_options.sample }
  let(:column8_file1) do
    content_path = "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif"
    tmp_ss_file(Cms::TempFile, site: site, user: user, node: node, contents: content_path)
  end
  let(:column8_image_text1) { unique_id }
  let(:column9_value1) { unique_id }
  # let(:column10_head1) { %w(h1 h2 h3 h4 h5).sample }
  let(:column10_head1) { %w(h1 h2).sample }
  let(:column10_text1) { unique_id }
  let(:column11_list1) { unique_id }
  let(:column12_value1) do
    <<~HTML
      <table>
        <caption>#{unique_id}</caption>
        <thead><tr><td>header1</td></tr></thead>
        <tbody><tr><td>cell1</td></tr></tbody>
      </table>
    HTML
  end
  let(:column13_youtube_id1) { unique_id }
  let(:column13_url1) { "https://www.youtube.com/watch?v=#{column13_youtube_id1}" }
  let(:column13_title1) { unique_id }
  let(:column14_page1) { selectable_page4 }

  let!(:article_page) do
    create(
      :article_page, cur_site: site, cur_node: node, form: form, state: %w(public closed).sample,
      column_values: [
        column1.value_type.new(
          column: column1, name: column1.name, value: column1_value1),
        column2.value_type.new(
          column: column2, name: column2.name, date: column2_value1),
        column3.value_type.new(
          column: column3, name: column3.name, link_url: column3_url1, link_label: column3_label1, link_target: column3_target1),
        column4.value_type.new(
          column: column4, name: column4.name, value: column4_value1),
        column5.value_type.new(
          column: column5, name: column5.name, value: column5_value1),
        column6.value_type.new(
          column: column6, name: column6.name, value: column6_value1),
        column7.value_type.new(
          column: column7, name: column7.name, values: [ column7_value1 ]),
        column8.value_type.new(
          column: column8, name: column8.name, file: column8_file1, file_label: column8_image_text1),
        column9.value_type.new(
          column: column9, name: column9.name, value: column9_value1),
        column10.value_type.new(
          column: column10, name: column10.name, head: column10_head1, text: column10_text1),
        column11.value_type.new(
          column: column11, name: column11.name, lists: [ column11_list1 ]),
        column12.value_type.new(
          column: column12, name: column12.name, value: column12_value1),
        column13.value_type.new(
          column: column13, name: column13.name, url: column13_url1, youtube_id: column13_youtube_id1, title: column13_title1),
        column14.value_type.new(
          column: column14, name: column14.name, page: column14_page1)
      ]
    )
  end

  around do |example|
    perform_enqueued_jobs do
      example.run
    end
  end

  context 'download with entry form' do
    before do
      node.st_form_ids = [ form.id ]
      node.save!
    end

    it do
      login_user user, to: article_pages_path(site: site, cid: node)
      wait_for_event_fired "turbo:frame-load" do
        wait_for_cbox_opened do
          click_on I18n.t("ss.links.download")
        end
      end

      wait_for_download("article_pages", extname: ".csv") do
        wait_for_event_fired "turbo:frame-load" do
          within_dialog do
            within "form#item-form" do
              choose "item[form_id]", option: form.id
              click_on I18n.t("ss.links.download")
            end
          end
        end
      end

      expect(Job::Log.count).to eq 1
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      expect(Cms::FileGenTask.all.site(site).count).to eq 1
      task = Cms::FileGenTask.all.site(site).first
      expect(task.job_id).to be_present
      expect(task.name).to start_with("article_pages_download_")
      expect(task.file_basename).to eq "article_pages"
      expect(task.file_format).to eq "csv"
      expect(task.params).to include("encoding" => "UTF-8", "form_id" => form.id.to_s, "truncate" => "yes")
      expect(File.size(task.generated_file_path)).to be > 0

      expect(SS::Notification.all.count).to eq 1
      notification = SS::Notification.all.first
      expect(notification.group_id).to be_blank
      expect(notification.member_ids).to eq [ cms_user.id ]
      expect(notification.user_id).to eq cms_user.id
      expect(notification.subject).to eq "[#{site.name}][#{node.name}] CSVダウンロード準備完了のお知らせ"
      expect(notification.text).to be_present
      path = Rails.application.routes.url_helpers.sns_apis_file_gen_task_download_path(id: task)
      expect(notification.text).to include(path)
      expect(notification.html).to be_blank
      expect(notification.format).to eq "text"
      expect(notification.user_settings).to be_blank
      expect(notification.state).to eq "public"
      expect(notification.send_date.in_time_zone).to be_within(30.seconds).of(Time.zone.now)
      expect(notification.url).to be_blank
      expect(notification.reply_module).to be_blank
      expect(notification.reply_model).to be_blank
      expect(notification.reply_item_id).to be_blank

      SS::Csv.open(downloaded_path) do |csv|
        csv_table = csv.read
        expect(csv_table.length).to eq 1
        csv_table[0].tap do |csv_row|
          expect(csv_row[Article::Page.t(:name)]).to eq article_page.name

          # 定型フォームの場合は、項目の値が出力されない
          [ form.name, column1.name, column1.value_type.t(:alignment) ].join("/").tap do |header|
            expect(csv_row.headers).not_to include(header)
          end
          [ form.name, column1.name, column1.value_type.t(:value) ].join("/").tap do |header|
            expect(csv_row.headers).not_to include(header)
          end
        end
      end
    end
  end
end
