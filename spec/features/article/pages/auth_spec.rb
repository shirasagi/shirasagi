require 'spec_helper'

describe "article_pages", dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create_once :article_node_page, filename: "docs", name: "article" }
  # let(:item) { create(:article_page, cur_node: node) }
  let(:index_path) { article_pages_path site.id, node }
  # let(:new_path) { new_article_page_path site.id, node }
  # let(:show_path) { article_page_path site.id, node, item }
  # let(:edit_path) { edit_article_page_path site.id, node, item }
  # let(:delete_path) { delete_article_page_path site.id, node, item }
  # let(:move_path) { move_article_page_path site.id, node, item }
  # let(:copy_path) { copy_article_page_path site.id, node, item }
  # let(:lock_path) { lock_article_page_path site.id, node, item }

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end
end
