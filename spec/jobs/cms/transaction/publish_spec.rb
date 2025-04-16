require 'spec_helper'
describe Cms::TransactionJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:plan) { create :cms_transaction_plan }
  let!(:unit) { create(:cms_transaction_unit_publisher, plan: plan, order: 10, filenames: filenames) }
  let!(:filenames) { [index.filename, page2.filename] }

  let!(:new_page_name) { unique_id }
  let!(:index) { create :cms_page, filename: "index.html", state: "closed" }
  let!(:docs) { create :article_node_page, filename: "docs" }
  let!(:page1) { create :article_page, filename: "docs/page1.html" }
  let!(:page2) do
    page1.cur_site = site
    page1.cur_node = docs
    page1.cur_user = user
    copy = page1.new_clone
    copy.master = page1
    copy.name = new_page_name
    copy.save!
    copy
  end

  it do
    ::Fs.rm_rf(index.path)
    ::Fs.rm_rf(docs.path)
    expect(::Fs.exist?(index.path)).to be_falsey
    expect(::Fs.exist?(page1.path)).to be_falsey

    expectation = expect { ss_perform_now(described_class.bind(site_id: site.id), plan_id: plan.id) }
    expectation.to output(include(unit.long_name)).to_stdout

    index.reload
    page1.reload
    expect(index.state).to eq "public"
    expect(page1.state).to eq "public"
    expect(page1.name).to eq new_page_name

    expect(::Fs.exist?(index.path)).to be_truthy
    expect(::Fs.exist?(page1.path)).to be_truthy

    expect(Cms::Page.all.pluck(:id)).to match_array [index.id, page1.id]
  end
end
