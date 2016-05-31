require 'spec_helper'

describe "inquiry_feedbacks", dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :inquiry_node_form, cur_site: site }
  let(:index_path) { inquiry_feedbacks_path(site, node) }

  let(:remote_addr) { "X.X.X.X" }
  let(:user_agent) { unique_id }
  let(:answer) { Inquiry::Answer.new(cur_site: site, cur_node: node, remote_addr: remote_addr, user_agent: user_agent) }

  let(:contents_column) { node.columns[0] }
  let(:findable_column) { node.columns[1] }
  let(:comment_column) { node.columns[2] }
  let(:contents_value) { contents_column.select_options.sample }
  let(:findable_value) { findable_column.select_options.sample }
  let(:comment_value) { "#{unique_id}\n#{unique_id}" }
  let(:page1) { create :cms_page, cur_site: site }

  before do
    node.columns.create! attributes_for(:inquiry_column_radio_contents).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_radio_findable).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_text_comment).reverse_merge({cur_site: site})
    node.reload
  end

  before do
    data = {}
    data[contents_column.id] = [contents_value]
    data[findable_column.id] = [findable_value]
    data[comment_column.id] = [comment_value]

    answer.source_url = page1.url
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
      click_on page1.name

      expect(page).to have_css(".main-box th", text: contents_column.name)
      expect(page).to have_css(".main-box th", text: findable_column.name)
      expect(page).to have_css(".main-box th", text: comment_column.name)
    end
  end

  context "search" do
    before { login_cms_user }

    it do
      visit index_path
      click_on "検索"
      click_on page1.name

      expect(page).to have_css(".main-box th", text: contents_column.name)
      expect(page).to have_css(".main-box th", text: findable_column.name)
      expect(page).to have_css(".main-box th", text: comment_column.name)
    end
  end
end
