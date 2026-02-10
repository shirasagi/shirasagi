require 'spec_helper'

describe "inquiry_answers", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:group) { cms_group }
  let!(:node) { create :inquiry_node_form, cur_site: site, group_ids: [ group.id ] }

  let(:remote_addr) { "X.X.X.X" }
  let(:user_agent) { unique_id }
  let(:answer) do
    Inquiry::Answer.new(
      cur_site: site, cur_node: node, remote_addr: remote_addr, user_agent: user_agent, group_ids: node.group_ids)
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

  context "basic crud with answer admin" do
    let!(:role) do
      permissions = %w(read_private_cms_nodes edit_private_cms_nodes read_private_inquiry_answers edit_private_inquiry_answers delete_private_inquiry_answers)
      create :cms_role, cur_site: site, name: unique_id, permissions: permissions
    end
    let!(:user) { create :cms_test_user, cur_site: site, cms_role_ids: [ role.id ], group_ids: [ group.id ] }

    before { login_user user, to: inquiry_forms_path(site: site, cid: node) }

    context "usual case" do
      it do
        within first(".mod-navi") do
          click_on I18n.t("inquiry.answer")
        end
        expect(page).to have_css(".list-item a", text: answer.data_summary)
        click_on answer.data_summary

        within '#menu' do
          expect(page).to have_no_link(I18n.t('inquiry.links.faq'))
        end
        expect(page).to have_css(".mod-inquiry-answer-body dt", text: name_column.name)
        expect(page).to have_css(".mod-inquiry-answer-body dd", text: name)
        expect(page).to have_css(".mod-inquiry-answer-body dt", text: email_column.name)
        expect(page).to have_css(".mod-inquiry-answer-body dd", text: email)
        expect(page).to have_css(".mod-inquiry-answer-body dt", text: radio_column.name)
        expect(page).to have_css(".mod-inquiry-answer-body dd", text: radio_value)
        expect(page).to have_css(".mod-inquiry-answer-body dt", text: select_column.name)
        expect(page).to have_css(".mod-inquiry-answer-body dd", text: select_value)
        expect(page).to have_css(".mod-inquiry-answer-body dt", text: same_as_name_column.name)
        expect(page).to have_css(".mod-inquiry-answer-body dd", text: same_as_name)

        expect(page).to have_css(".mod-inquiry-answer-body dd", text: remote_addr)
        expect(page).to have_css(".mod-inquiry-answer-body dd", text: user_agent)

        click_on I18n.t("ss.links.delete")
        within "form#item-form" do
          click_on I18n.t("ss.buttons.delete")
        end
        wait_for_notice I18n.t("ss.notice.deleted")

        expect(page).to have_no_css(".list-item a", text: answer.data_summary)
        expect(Inquiry::Answer.count).to eq 0
      end
    end

    context "when a column was destroyed after answers ware committed" do
      before { email_column.destroy }

      it do
        within first(".mod-navi") do
          click_on I18n.t("inquiry.answer")
        end
        expect(page).to have_css(".list-item a", text: answer.data_summary)
        click_on answer.data_summary

        within '#menu' do
          expect(page).to have_no_link(I18n.t('inquiry.links.faq'))
        end
        expect(page).to have_css(".mod-inquiry-answer-body dt", text: name_column.name)
        expect(page).to have_css(".mod-inquiry-answer-body dd", text: name)
        expect(page).to have_css(".mod-inquiry-answer-body dt", text: radio_column.name)
        expect(page).to have_css(".mod-inquiry-answer-body dd", text: radio_value)
        expect(page).to have_css(".mod-inquiry-answer-body dt", text: select_column.name)
        expect(page).to have_css(".mod-inquiry-answer-body dd", text: select_value)
        expect(page).to have_css(".mod-inquiry-answer-body dt", text: same_as_name_column.name)
        expect(page).to have_css(".mod-inquiry-answer-body dd", text: same_as_name)

        expect(page).to have_css(".mod-inquiry-answer-body dd", text: remote_addr)
        expect(page).to have_css(".mod-inquiry-answer-body dd", text: user_agent)

        click_on I18n.t("ss.links.delete")
        within "form#item-form" do
          click_on I18n.t("ss.buttons.delete")
        end
        wait_for_notice I18n.t("ss.notice.deleted")

        expect(page).to have_no_css(".list-item a", text: answer.data_summary)
        expect(Inquiry::Answer.count).to eq 0
      end
    end

    context "edit answer state" do
      it do
        within first(".mod-navi") do
          click_on I18n.t("inquiry.answer")
        end
        expect(page).to have_css(".list-item a", text: answer.data_summary)

        within ".list-items" do
          expect(page).to have_text((answer.label :state))
        end

        click_on answer.data_summary
        expect(page).to have_text I18n.t("inquiry.options.answer_state.open")

        click_on I18n.t("ss.links.edit")

        within "form#item-form" do
          select I18n.t("inquiry.options.answer_state.closed"), from: 'item[state]'
          fill_in "item[comment]", with: "comment"
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        Inquiry::Answer.find(answer.id).tap do |answer_after_closed|
          expect(answer_after_closed.state).to eq "closed"
          expect(answer_after_closed.comment).to eq "comment"
          expect(answer_after_closed.data_summary).to eq answer.data_summary
        end

        click_on I18n.t("ss.links.back_to_index")
        expect(page).to have_text I18n.t("inquiry.options.answer_state.closed")

        within ".list-items" do
          expect(page).to have_css(".list-item[data-id]", count: 0)
          expect(page).to have_no_text(I18n.t("inquiry.options.answer_state.closed"))
        end
      end
    end
  end

  context "basic crud with answer charge" do
    let!(:role) do
      permissions = %w(read_private_cms_nodes read_private_inquiry_answers edit_private_inquiry_answers)
      create :cms_role, cur_site: site, name: unique_id, permissions: permissions
    end
    let!(:user) { create :cms_test_user, cur_site: site, cms_role_ids: [ role.id ], group_ids: [ group.id ] }

    before { login_user user, to: inquiry_forms_path(site: site, cid: node) }

    context "usual case" do
      it do
        within first(".mod-navi") do
          click_on I18n.t("inquiry.answer")
        end
        expect(page).to have_css(".list-item a", text: answer.data_summary)
        click_on answer.data_summary

        expect(page).to have_css(".mod-inquiry-answer-body dt", text: name_column.name)
        expect(page).to have_css(".mod-inquiry-answer-body dd", text: name)
        expect(page).to have_css(".mod-inquiry-answer-body dt", text: email_column.name)
        expect(page).to have_css(".mod-inquiry-answer-body dd", text: email)
        expect(page).to have_css(".mod-inquiry-answer-body dt", text: radio_column.name)
        expect(page).to have_css(".mod-inquiry-answer-body dd", text: radio_value)
        expect(page).to have_css(".mod-inquiry-answer-body dt", text: select_column.name)
        expect(page).to have_css(".mod-inquiry-answer-body dd", text: select_value)
        expect(page).to have_css(".mod-inquiry-answer-body dt", text: same_as_name_column.name)
        expect(page).to have_css(".mod-inquiry-answer-body dd", text: same_as_name)

        expect(page).to have_css(".mod-inquiry-answer-body dd", text: remote_addr)
        expect(page).to have_css(".mod-inquiry-answer-body dd", text: user_agent)

        within ".nav-menu" do
          expect(page).to have_no_link(I18n.t("ss.links.delete"))
          click_on I18n.t("ss.links.edit")
        end

        within "form#item-form" do
          select I18n.t("inquiry.options.answer_state.closed"), from: 'item[state]'
          fill_in "item[comment]", with: "comment"
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        Inquiry::Answer.find(answer.id).tap do |answer_after_closed|
          expect(answer_after_closed.state).to eq "closed"
          expect(answer_after_closed.comment).to eq "comment"
          expect(answer_after_closed.data_summary).to eq answer.data_summary
        end
      end
    end
  end
end
