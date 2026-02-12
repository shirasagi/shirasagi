require 'spec_helper'

describe "inquiry_results", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:group0) { cms_group }
  let!(:group1) { create :cms_group, name: "#{group0.name}/#{unique_id}" }
  let!(:group2) { create :cms_group, name: "#{group0.name}/#{unique_id}" }
  let!(:layout) { create_cms_layout cur_site: site }
  let!(:node) { create :inquiry_node_form, cur_site: site, layout: layout, group_ids: [ group1.id, group2.id ] }

  let(:remote_addr) { "X.X.X.X" }
  let(:user_agent) { unique_id }
  let(:answer1) do
    Inquiry::Answer.new(
      cur_site: site, cur_node: node, remote_addr: remote_addr, user_agent: user_agent, group_ids: [ group1.id ])
  end
  let(:answer2) do
    Inquiry::Answer.new(
      cur_site: site, cur_node: node, remote_addr: remote_addr, user_agent: user_agent, group_ids: [ group2.id ])
  end

  let(:name_column) { node.columns[0] }
  let(:company_column) { node.columns[1] }
  let(:email_column) { node.columns[2] }
  let(:radio_column) { node.columns[3] }
  let(:select_column) { node.columns[4] }
  let(:check_column) { node.columns[5] }
  let(:same_as_name_column) { node.columns[6] }

  let(:name1) { unique_id }
  let(:email1) { "#{unique_id}@example.jp" }
  let(:radio_value1) { radio_column.select_options.sample }
  let(:select_value1) { select_column.select_options.sample }
  let(:check_value1) { Hash[check_column.select_options.map.with_index { |val, i| [i.to_s, val] }.sample(2)] }
  let(:same_as_name1) { unique_id }

  let(:name2) { unique_id }
  let(:email2) { "#{unique_id}@example.jp" }
  let(:radio_value2) { radio_column.select_options.sample }
  let(:select_value2) { select_column.select_options.sample }
  let(:check_value2) { Hash[check_column.select_options.map.with_index { |val, i| [i.to_s, val] }.sample(2)] }
  let(:same_as_name2) { unique_id }

  before do
    node.columns.create! attributes_for(:inquiry_column_name).reverse_merge({cur_site: site}).merge(question: 'enabled')
    node.columns.create! attributes_for(:inquiry_column_optional).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_email).reverse_merge({cur_site: site}).merge(question: 'enabled')
    node.columns.create! attributes_for(:inquiry_column_radio).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_select).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_check).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_same_as_name).reverse_merge({cur_site: site})
    node.reload
  end

  before do
    {}.tap do |data|
      data[name_column.id] = [name1]
      data[email_column.id] = [email1, email1]
      data[radio_column.id] = [radio_value1]
      data[select_column.id] = [select_value1]
      data[check_column.id] = [check_value1]
      data[same_as_name_column.id] = [same_as_name1]

      answer1.set_data(data)
      answer1.save!
    end

    {}.tap do |data|
      data[name_column.id] = [name2]
      data[email_column.id] = [email2, email2]
      data[radio_column.id] = [radio_value2]
      data[select_column.id] = [select_value2]
      data[check_column.id] = [check_value2]
      data[same_as_name_column.id] = [same_as_name2]

      answer2.set_data(data)
      answer2.save!
    end
  end

  context "basic crud with answer charge" do
    let!(:role) do
      permissions = %w(read_private_cms_nodes read_private_inquiry_answers edit_private_inquiry_answers)
      create :cms_role, cur_site: site, name: unique_id, permissions: permissions
    end
    let!(:user) { create :cms_test_user, cur_site: site, cms_role_ids: [ role.id ], group_ids: [ group1.id ] }

    before { login_user user, to: inquiry_forms_path(site: site, cid: node) }

    context "usual case" do
      it do
        within first(".mod-navi") do
          click_on I18n.t("inquiry.result")
        end
        within "[data-column-id='main']" do
          expect(page).to have_content("1#{I18n.t("ss.units.count")}")
        end
        within "[data-column-id='#{name_column.id}']" do
          expect(page).to have_content(name1)
          expect(page).to have_no_content(name2)
        end
        within "[data-column-id='#{email_column.id}']" do
          expect(page).to have_content(email1)
          expect(page).to have_no_content(email2)
        end

        click_on I18n.t("ss.links.download")
        wait_for_download
        SS::Csv.open(downloads.first, headers: false) do |csv|
          csv_table = csv.read
          expect(csv_table.length).to be >= 10
          csv_table[0].tap do |csv_row_summary|
            expect(csv_row_summary[0]).to eq I18n.t("inquiry.total_count")
            expect(csv_row_summary[1]).to eq "1"
          end

          csv_table[2].tap do |csv_row_column_name|
            expect(csv_row_column_name[0]).to eq name_column.name
          end
          csv_table[3].tap do |csv_row_column_value|
            expect(csv_row_column_value[0]).to eq name1
          end

          csv_values = csv_table.to_a.flatten
          expect(csv_values).to include(name1, email1)
          expect(csv_values).not_to include(name2, email2)
        end

        new_window = window_opened_by { click_on I18n.t('ss.links.preview') }
        within_window new_window do
          wait_for_document_loading
          wait_for_js_ready

          # 公開画面をプレビュー表示するので、権限がない回答も件数に含まれている
          within ".column.count" do
            expect(page).to have_content("2 #{I18n.t("ss.units.count")}")
          end
        end
      end
    end
  end
end
