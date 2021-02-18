require 'spec_helper'

describe "inquiry_answers", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:faq_node) { create :faq_node_page, cur_site: site }
  let(:node) { create :inquiry_node_form, cur_site: site, faq: faq_node }
  let(:index_path) { inquiry_answers_path(site, node) }

  let(:remote_addr) { "X.X.X.X" }
  let(:user_agent) { unique_id }
  let(:answer) { Inquiry::Answer.new(cur_site: site, cur_node: node, remote_addr: remote_addr, user_agent: user_agent) }

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

  context "search" do
    before { login_cms_user }

    context "usual case" do
      it do
        visit index_path
        expect(page).to have_css(".list-item a", text: answer.data_summary)
        click_on I18n.t("ss.buttons.search")
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

        click_on I18n.t("ss.links.delete")
        click_on I18n.t("ss.buttons.delete")

        expect(page).to have_no_css(".list-item a", text: answer.data_summary)
        expect(Inquiry::Answer.count).to eq 0
      end
    end

    context "when a column was destroyed after answers ware committed" do
      before { email_column.destroy }

      it do
        visit index_path
        expect(page).to have_css(".list-item a", text: answer.data_summary)
        click_on I18n.t("ss.buttons.search")
        click_on answer.data_summary

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
        click_on I18n.t("ss.buttons.delete")

        expect(page).to have_no_css(".list-item a", text: answer.data_summary)
        expect(Inquiry::Answer.count).to eq 0
      end
    end
  end
end
