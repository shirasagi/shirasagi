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

  context "basic crud" do
    before { login_cms_user }

    context "usual case" do
      it do
        visit index_path
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

    context "edit answer state" do
      it do
        visit index_path
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

        click_on I18n.t("ss.links.back_to_index")
        expect(page).to have_text I18n.t("inquiry.options.answer_state.closed")

        within ".list-items" do
          expect(page).not_to have_text I18n.t("inquiry.options.answer_state.closed")
        end

        # unclosed
        within "form.index-search" do
          select I18n.t("inquiry.options.search_answer_state.unclosed"), from: 's[state]'
          click_on I18n.t("ss.buttons.search")
        end

        within ".list-items" do
          expect(page).not_to have_text I18n.t("inquiry.options.answer_state.closed")
        end

        # open
        within "form.index-search" do
          select I18n.t("inquiry.options.search_answer_state.open"), from: 's[state]'
          click_on I18n.t("ss.buttons.search")
        end

        within ".list-items" do
          expect(page).not_to have_text I18n.t("inquiry.options.answer_state.closed")
        end

        # closed
        within "form.index-search" do
          select I18n.t("inquiry.options.search_answer_state.closed"), from: 's[state]'
          click_on I18n.t("ss.buttons.search")
        end

        within ".list-items" do
          expect(page).to have_text I18n.t("inquiry.options.answer_state.closed")
        end

        # all
        within "form.index-search" do
          select I18n.t("inquiry.options.search_answer_state.all"), from: 's[state]'
          click_on I18n.t("ss.buttons.search")
        end

        within ".list-items" do
          expect(page).to have_text I18n.t("inquiry.options.answer_state.closed")
        end
      end
    end
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

  context "download" do
    before { login_cms_user }

    context "usual case" do
      it do
        visit index_path
        expect(page).to have_css(".list-item a", text: answer.data_summary)
        click_on I18n.t('ss.links.download')
        expect(status_code).to eq 200

        csv_lines = CSV.parse(page.html.encode("UTF-8"))
        expect(csv_lines.length).to eq 2
        expect(csv_lines[0][0]).to eq 'id'
        expect(csv_lines[0][1]).to eq((answer.t :state))
        expect(csv_lines[0][2]).to eq((answer.t :comment))
        expect(csv_lines[0][3]).to eq name_column.name
        expect(csv_lines[0][4]).to eq company_column.name
        expect(csv_lines[0][5]).to eq email_column.name
        expect(csv_lines[0][6]).to eq radio_column.name
        expect(csv_lines[0][7]).to eq select_column.name
        expect(csv_lines[0][8]).to eq check_column.name
        expect(csv_lines[0][9]).to eq same_as_name_column.name
        expect(csv_lines[0][10]).to eq Inquiry::Answer.t('source_url')
        expect(csv_lines[0][11]).to eq Inquiry::Answer.t('source_name')
        expect(csv_lines[0][12]).to eq Inquiry::Answer.t('created')

        expect(csv_lines[1][0]).to eq answer.id.to_s
        expect(csv_lines[1][1]).to eq((answer.label :state))
        expect(csv_lines[1][2]).to eq answer.comment
        expect(csv_lines[1][3]).to eq name
        expect(csv_lines[1][4]).to be_nil
        expect(csv_lines[1][5]).to eq email
        expect(csv_lines[1][6]).to eq radio_value
        expect(csv_lines[1][7]).to eq select_value
        expect(csv_lines[1][8]).to eq check_value.values.join("\n")
        expect(csv_lines[1][9]).to eq same_as_name
        expect(csv_lines[1][10]).to be_nil
        expect(csv_lines[1][11]).to be_nil
        expect(csv_lines[1][12]).to eq answer.created.strftime('%Y/%m/%d %H:%M')

      end
    end

    context "when a column was destroyed after answers ware committed" do
      before { email_column.destroy }

      it do
        visit index_path
        expect(page).to have_css(".list-item a", text: answer.data_summary)
        click_on I18n.t('ss.links.download')
        expect(status_code).to eq 200

        csv_lines = CSV.parse(page.html.encode("UTF-8"))
        expect(csv_lines.length).to eq 2

        expect(csv_lines[0][0]).to eq 'id'
        expect(csv_lines[0][1]).to eq((answer.t :state))
        expect(csv_lines[0][2]).to eq((answer.t :comment))
        expect(csv_lines[0][3]).to eq name_column.name
        expect(csv_lines[0][4]).to eq company_column.name
        expect(csv_lines[0][5]).to eq radio_column.name
        expect(csv_lines[0][6]).to eq select_column.name
        expect(csv_lines[0][7]).to eq check_column.name
        expect(csv_lines[0][8]).to eq same_as_name_column.name
        expect(csv_lines[0][9]).to eq Inquiry::Answer.t('source_url')
        expect(csv_lines[0][10]).to eq Inquiry::Answer.t('source_name')
        expect(csv_lines[0][11]).to eq Inquiry::Answer.t('created')

        expect(csv_lines[1][0]).to eq answer.id.to_s
        expect(csv_lines[1][1]).to eq((answer.label :state))
        expect(csv_lines[1][2]).to eq answer.comment
        expect(csv_lines[1][3]).to eq name
        expect(csv_lines[1][4]).to be_nil
        expect(csv_lines[1][5]).to eq radio_value
        expect(csv_lines[1][6]).to eq select_value
        expect(csv_lines[1][7]).to eq check_value.values.join("\n")
        expect(csv_lines[1][8]).to eq same_as_name
        expect(csv_lines[1][9]).to be_nil
        expect(csv_lines[1][10]).to be_nil
        expect(csv_lines[1][11]).to eq answer.created.strftime('%Y/%m/%d %H:%M')
      end
    end
  end

  context "when create faq/page that use inquiry/answer" do
    before { login_cms_user }

    context "usual case" do
      it do
        visit index_path
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

        expect(page).to have_css('#menu a', text: "FAQを新規作成")
        click_on "FAQを新規作成"
        expect(page).to have_css("#item_question", text: [name, email].join(','))
      end
    end

    context "when a column was destroyed after answers ware committed" do
      before { email_column.destroy }

      it do
        visit index_path
        expect(page).to have_css(".list-item a", text: answer.data_summary)
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

        expect(page).to have_css('#menu a', text: "FAQを新規作成")
        click_on "FAQを新規作成"
        expect(page).to have_css("#item_question", text: name)
      end
    end
  end
end
