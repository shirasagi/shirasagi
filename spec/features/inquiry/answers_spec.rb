require 'spec_helper'

describe "inquiry_answers", dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :inquiry_node_form, cur_site: site }
  let(:index_path) { inquiry_answers_path(site, node) }

  let(:remote_addr) { "X.X.X.X" }
  let(:user_agent) { unique_id }
  let(:answer) { Inquiry::Answer.new(cur_site: site, cur_node: node, remote_addr: remote_addr, user_agent: user_agent) }

  let(:name) { unique_id }
  let(:email) { "#{unique_id}@example.jp" }
  let(:email_confirmation) { email }
  let(:radio) { radio_column.select_options.sample }
  let(:select) { select_column.select_options.sample }
  let(:check) { Hash[check_column.select_options.map.with_index { |val, i| [i.to_s, val] }.sample(2)] }
  let(:name_column) { node.columns[0] }
  let(:email_column) { node.columns[2] }
  let(:radio_column) { node.columns[3] }
  let(:select_column) { node.columns[4] }
  let(:check_column) { node.columns[5] }

  before do
    node.columns.create! attributes_for(:inquiry_column_name).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_optional).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_email).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_radio).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_select).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_check).reverse_merge({cur_site: site})
    node.reload
  end

  before do
    data = {}
    data[name_column.id] = [name]
    data[email_column.id] = [email, email]
    data[radio_column.id] = [radio]
    data[select_column.id] = [select]
    data[check_column.id] = [check]

    answer.set_data(data)
    answer.save!
  end

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  context "basic crud" do
    before { login_cms_user }

    it do
      visit index_path
      expect(page).to have_css(".list-item a", text: answer.data_summary)
      click_on answer.data_summary

      expect(page).to have_css("#addon-basic dt", text: name_column.name)
      expect(page).to have_css("#addon-basic dd", text: name)
      expect(page).to have_css("#addon-basic dt", text: email_column.name)
      expect(page).to have_css("#addon-basic dd", text: email)
      expect(page).to have_css("#addon-basic dt", text: radio_column.name)
      expect(page).to have_css("#addon-basic dd", text: radio)
      expect(page).to have_css("#addon-basic dt", text: select_column.name)
      expect(page).to have_css("#addon-basic dd", text: select)

      expect(page).to have_css("#addon-basic dd", text: remote_addr)
      expect(page).to have_css("#addon-basic dd", text: user_agent)

      click_on "削除する"
      click_on "削除"

      expect(page).not_to have_css(".list-item a", text: answer.data_summary)
      expect(Inquiry::Answer.count).to eq 0
    end
  end

  context "search" do
    before { login_cms_user }

    it do
      visit index_path
      expect(page).to have_css(".list-item a", text: answer.data_summary)
      click_on "検索"
      click_on answer.data_summary

      expect(page).to have_css("#addon-basic dt", text: name_column.name)
      expect(page).to have_css("#addon-basic dd", text: name)
      expect(page).to have_css("#addon-basic dt", text: email_column.name)
      expect(page).to have_css("#addon-basic dd", text: email)
      expect(page).to have_css("#addon-basic dt", text: radio_column.name)
      expect(page).to have_css("#addon-basic dd", text: radio)
      expect(page).to have_css("#addon-basic dt", text: select_column.name)
      expect(page).to have_css("#addon-basic dd", text: select)

      expect(page).to have_css("#addon-basic dd", text: remote_addr)
      expect(page).to have_css("#addon-basic dd", text: user_agent)

      click_on "削除する"
      click_on "削除"

      expect(page).not_to have_css(".list-item a", text: answer.data_summary)
      expect(Inquiry::Answer.count).to eq 0
    end
  end

end
