require 'spec_helper'
require Rails.root.join("lib/migrations/cms/20200625000000_fix_shared_thumb.rb")

RSpec.describe SS::Migration20200625000000, dbscope: :example do
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:node) { create :article_node_page, cur_user: user, cur_site: site }
  let!(:thumb1) { tmp_ss_file(user: user, site: site, contents: "#{Rails.root}/spec/fixtures/ss/logo.png") }
  let!(:thumb2) { tmp_ss_file(user: user, site: site, contents: "#{Rails.root}/spec/fixtures/ss/logo.png") }
  # page1 and page2 share same thumb
  let!(:page1) { create :article_page, cur_user: user, cur_site: site, cur_node: node, thumb_id: thumb1.id }
  let!(:page2) { create :article_page, cur_user: user, cur_site: site, cur_node: node }
  # page3's thumb has been deleted
  let!(:page3) { create :article_page, cur_user: user, cur_site: site, cur_node: node, thumb_id: thumb2.id }

  before do
    thumb1.reload
    expect(thumb1.owner_item.id).to eq page1.id

    thumb2.reload
    expect(thumb2.owner_item.id).to eq page3.id

    page2.set(thumb_id: thumb1.id)
    thumb2.destroy

    # do migration
    described_class.new.change
  end

  it do
    # put your specs here
    page1.reload
    expect(page1.thumb.id).to eq thumb1.id

    page2.reload
    expect(page2.thumb.id).not_to eq thumb1.id

    page3.reload
    expect(page3.thumb_id).to eq thumb2.id
  end
end
