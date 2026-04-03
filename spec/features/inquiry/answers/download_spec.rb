require 'spec_helper'

describe "inquiry_answers", type: :feature, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }
  let!(:site) { cms_site }
  let!(:group0) { cms_group }
  let!(:group1) { create :cms_group, name: "#{group0.name}/#{unique_id}" }
  let!(:group2) { create :cms_group, name: "#{group0.name}/#{unique_id}" }
  let!(:node) { create :inquiry_node_form, cur_site: site, group_ids: [ group1.id, group2.id ] }

  let(:remote_addr) { "X.X.X.X" }
  let(:user_agent) { unique_id }
  let(:state) { Inquiry::Answer::DEFAULT_STATE }
  let(:comment) { "comment-#{unique_id}" }
  let(:answer1) do
    Timecop.freeze(now - 5.hours) do
      Inquiry::Answer.new(
        cur_site: site, cur_node: node, remote_addr: remote_addr, user_agent: user_agent, state: state, comment: comment,
        group_ids: [ group1.id ])
    end
  end
  let(:answer2) do
    Timecop.freeze(now - 4.hours) do
      Inquiry::Answer.new(
        cur_site: site, cur_node: node, remote_addr: remote_addr, user_agent: user_agent, state: state, comment: comment,
        group_ids: [ group2.id ])
    end
  end

  let(:name) { unique_id }
  let(:email) { "#{unique_id}@example.jp" }
  let(:email_confirmation) { email }
  let(:radio_value) { radio_column.select_options.sample }
  let(:select_value) { select_column.select_options.sample }
  let(:check_value) { Hash[check_column.select_options.map.with_index { |val, i| [i.to_s, val] }.sample(2)] }
  let(:same_as_name) { unique_id }
  let(:name_column) { node.columns[0] }
  let(:company_column) { node.columns[1] }
  let(:email_column) { node.columns[2] }
  let(:radio_column) { node.columns[3] }
  let(:select_column) { node.columns[4] }
  let(:check_column) { node.columns[5] }
  let(:same_as_name_column) { node.columns[6] }

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
    [ answer1, answer2 ].each do |answer|
      data = {}
      data[name_column.id] = [name]
      data[email_column.id] = [email, email]
      data[radio_column.id] = [radio_value]
      data[select_column.id] = [select_value]
      data[check_column.id] = [check_value]
      data[same_as_name_column.id] = [same_as_name]

      answer.set_data(data)
      answer.save!
    end
  end

  context "download with answer charge" do
    let!(:role) do
      permissions = %w(read_private_cms_nodes read_private_inquiry_answers edit_private_inquiry_answers)
      create :cms_role, cur_site: site, name: unique_id, permissions: permissions
    end
    let!(:user) { create :cms_test_user, cur_site: site, cms_role_ids: [ role.id ], group_ids: [ group1.id ] }

    before { login_user user, to: inquiry_forms_path(site: site, cid: node) }

    context "usual case" do
      it do
        within first(".mod-navi") do
          click_on I18n.t("inquiry.answer")
        end
        expect(page).to have_css(".list-item a", text: answer1.data_summary)
        click_on I18n.t('ss.links.download')
        expect(status_code).to eq 200

        csv_lines = CSV.parse(page.html.encode("UTF-8"))
        expect(csv_lines.length).to eq 2
        expect(csv_lines[0][0]).to eq 'id'
        expect(csv_lines[0][1]).to eq((Inquiry::Answer.t(:state)))
        expect(csv_lines[0][2]).to eq((Inquiry::Answer.t(:comment)))
        expect(csv_lines[0][3]).to eq name_column.name
        expect(csv_lines[0][4]).to eq company_column.name
        expect(csv_lines[0][5]).to eq email_column.name
        expect(csv_lines[0][6]).to eq radio_column.name
        expect(csv_lines[0][7]).to eq select_column.name
        expect(csv_lines[0][8]).to eq check_column.name
        expect(csv_lines[0][9]).to eq same_as_name_column.name
        expect(csv_lines[0][10]).to eq Inquiry::Answer.t('source_url')
        expect(csv_lines[0][11]).to eq Inquiry::Answer.t('source_name')
        expect(csv_lines[0][12]).to eq Inquiry::Answer.t('inquiry_page_url')
        expect(csv_lines[0][13]).to eq Inquiry::Answer.t('inquiry_page_name')
        expect(csv_lines[0][14]).to eq Inquiry::Answer.t('created')
        expect(csv_lines[0][15]).to eq Inquiry::Answer.t('updated')
        expect(csv_lines[1][0]).to eq answer1.id.to_s
        expect(csv_lines[1][1]).to eq answer1.label(:state)
        expect(csv_lines[1][2]).to eq answer1.comment
        expect(csv_lines[1][3]).to eq name
        expect(csv_lines[1][4]).to be_nil
        expect(csv_lines[1][5]).to eq email
        expect(csv_lines[1][6]).to eq radio_value
        expect(csv_lines[1][7]).to eq select_value
        expect(csv_lines[1][8]).to eq check_value.values.join("\n")
        expect(csv_lines[1][9]).to eq same_as_name
        expect(csv_lines[1][10]).to be_nil
        expect(csv_lines[1][11]).to be_nil
        expect(csv_lines[1][12]).to be_nil
        expect(csv_lines[1][13]).to be_nil
        expect(csv_lines[1][14]).to eq answer1.created.strftime('%Y/%m/%d %H:%M')
        expect(csv_lines[1][15]).to eq answer1.updated.strftime('%Y/%m/%d %H:%M')
      end
    end

    context "when a column was destroyed after answers ware committed" do
      before { email_column.destroy }

      it do
        within first(".mod-navi") do
          click_on I18n.t("inquiry.answer")
        end
        expect(page).to have_css(".list-item a", text: answer1.data_summary)
        click_on I18n.t('ss.links.download')
        expect(status_code).to eq 200

        csv_lines = CSV.parse(page.html.encode("UTF-8"))
        expect(csv_lines.length).to eq 2

        expect(csv_lines[0][0]).to eq 'id'
        expect(csv_lines[0][1]).to eq((Inquiry::Answer.t(:state)))
        expect(csv_lines[0][2]).to eq((Inquiry::Answer.t(:comment)))
        expect(csv_lines[0][3]).to eq name_column.name
        expect(csv_lines[0][4]).to eq company_column.name
        expect(csv_lines[0][5]).to eq radio_column.name
        expect(csv_lines[0][6]).to eq select_column.name
        expect(csv_lines[0][7]).to eq check_column.name
        expect(csv_lines[0][8]).to eq same_as_name_column.name
        expect(csv_lines[0][9]).to eq Inquiry::Answer.t('source_url')
        expect(csv_lines[0][10]).to eq Inquiry::Answer.t('source_name')
        expect(csv_lines[0][11]).to eq Inquiry::Answer.t('inquiry_page_url')
        expect(csv_lines[0][12]).to eq Inquiry::Answer.t('inquiry_page_name')
        expect(csv_lines[0][13]).to eq Inquiry::Answer.t('created')
        expect(csv_lines[0][14]).to eq Inquiry::Answer.t('updated')
        expect(csv_lines[1][0]).to eq answer1.id.to_s
        expect(csv_lines[1][1]).to eq answer1.label(:state)
        expect(csv_lines[1][2]).to eq answer1.comment
        expect(csv_lines[1][3]).to eq name
        expect(csv_lines[1][4]).to be_nil
        expect(csv_lines[1][5]).to eq radio_value
        expect(csv_lines[1][6]).to eq select_value
        expect(csv_lines[1][7]).to eq check_value.values.join("\n")
        expect(csv_lines[1][8]).to eq same_as_name
        expect(csv_lines[1][9]).to be_nil
        expect(csv_lines[1][10]).to be_nil
        expect(csv_lines[1][11]).to be_nil
        expect(csv_lines[1][12]).to be_nil
        expect(csv_lines[1][13]).to eq answer1.created.strftime('%Y/%m/%d %H:%M')
        expect(csv_lines[1][14]).to eq answer1.updated.strftime('%Y/%m/%d %H:%M')
      end
    end

    context "with source_url" do
      let(:answer2) { Inquiry::Answer.new(cur_site: site, cur_node: node, remote_addr: remote_addr, user_agent: user_agent) }

      before do
        answer1.update!(source_url: source_url)
      end

      context "path (normal case)" do
        let(:source_url) { "/docs/page.html" }

        it do
          within first(".mod-navi") do
            click_on I18n.t("inquiry.answer")
          end
          click_on I18n.t('ss.links.download')
          expect(status_code).to eq 200

          csv_lines = CSV.parse(page.html.encode("UTF-8"))
          expect(csv_lines.length).to eq 2
          expect(csv_lines[1][10]).to eq ::File.join(site.full_url, source_url)
        end
      end

      context "full_url (invalid case?)" do
        let(:source_url) { "https://sample.example.jp" }

        it do
          within first(".mod-navi") do
            click_on I18n.t("inquiry.answer")
          end
          click_on I18n.t('ss.links.download')
          expect(status_code).to eq 200

          csv_lines = CSV.parse(page.html.encode("UTF-8"))
          expect(csv_lines.length).to eq 2
          expect(csv_lines[1][10]).to eq source_url
        end
      end
    end
  end

  context "download with site admin" do
    let!(:user) { cms_user }

    before { login_user user, to: inquiry_forms_path(site: site, cid: node) }

    context "usual case" do
      it do
        within first(".mod-navi") do
          click_on I18n.t("inquiry.answer")
        end
        expect(page).to have_css(".list-item a", text: answer1.data_summary)
        expect(page).to have_css(".list-item a", text: answer2.data_summary)
        click_on I18n.t('ss.links.download')
        expect(status_code).to eq 200

        csv_lines = CSV.parse(page.html.encode("UTF-8"))
        expect(csv_lines.length).to eq 3
        # 並び順は updated: -1
        expect(csv_lines[0][0]).to eq 'id'
        expect(csv_lines[0][1]).to eq((Inquiry::Answer.t(:state)))
        expect(csv_lines[0][2]).to eq((Inquiry::Answer.t(:comment)))
        expect(csv_lines[0][3]).to eq name_column.name
        expect(csv_lines[0][4]).to eq company_column.name
        expect(csv_lines[0][5]).to eq email_column.name
        expect(csv_lines[0][6]).to eq radio_column.name
        expect(csv_lines[0][7]).to eq select_column.name
        expect(csv_lines[0][8]).to eq check_column.name
        expect(csv_lines[0][9]).to eq same_as_name_column.name
        expect(csv_lines[0][10]).to eq Inquiry::Answer.t('source_url')
        expect(csv_lines[0][11]).to eq Inquiry::Answer.t('source_name')
        expect(csv_lines[0][12]).to eq Inquiry::Answer.t('inquiry_page_url')
        expect(csv_lines[0][13]).to eq Inquiry::Answer.t('inquiry_page_name')
        expect(csv_lines[0][14]).to eq Inquiry::Answer.t('created')
        expect(csv_lines[0][15]).to eq Inquiry::Answer.t('updated')
        expect(csv_lines[1][0]).to eq answer2.id.to_s
        expect(csv_lines[1][1]).to eq answer2.label(:state)
        expect(csv_lines[1][2]).to eq answer2.comment
        expect(csv_lines[1][3]).to eq name
        expect(csv_lines[1][4]).to be_nil
        expect(csv_lines[1][5]).to eq email
        expect(csv_lines[1][6]).to eq radio_value
        expect(csv_lines[1][7]).to eq select_value
        expect(csv_lines[1][8]).to eq check_value.values.join("\n")
        expect(csv_lines[1][9]).to eq same_as_name
        expect(csv_lines[1][10]).to be_nil
        expect(csv_lines[1][11]).to be_nil
        expect(csv_lines[1][12]).to be_nil
        expect(csv_lines[1][13]).to be_nil
        expect(csv_lines[1][14]).to eq answer2.created.strftime('%Y/%m/%d %H:%M')
        expect(csv_lines[1][15]).to eq answer2.updated.strftime('%Y/%m/%d %H:%M')
      end
    end
  end
end
