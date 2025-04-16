require 'spec_helper'
describe Cms::TransactionJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:plan) { create :cms_transaction_plan }
  let!(:unit) { create(:cms_transaction_unit_generation, plan: plan, order: 10, filenames: filenames) }
  let!(:filenames) { [index.filename, docs.filename, page1.filename] }

  let!(:index) { create :cms_page, filename: "index.html" }
  let!(:docs) { create :article_node_page, filename: "docs" }
  let!(:page1) { create :article_page, filename: "docs/page1.html" }
  let!(:page2) { create :article_page, filename: "docs/page2.html" }

  it do
    ::Fs.rm_rf(index.path)
    ::Fs.rm_rf(docs.path)

    expect(::Fs.exist?(index.path)).to be_falsey
    expect(::Fs.exist?(::File.join(docs.path, "index.html"))).to be_falsey
    expect(::Fs.exist?(page1.path)).to be_falsey
    expect(::Fs.exist?(page2.path)).to be_falsey

    expectation = expect { ss_perform_now(described_class.bind(site_id: site.id), plan_id: plan.id) }
    expectation.to output(include(unit.long_name)).to_stdout

    expect(::Fs.exist?(index.path)).to be_truthy
    expect(::Fs.exist?(::File.join(docs.path, "index.html"))).to be_truthy
    expect(::Fs.exist?(::File.join(docs.path, "rss.xml"))).to be_truthy
    expect(::Fs.exist?(page1.path)).to be_truthy
    expect(::Fs.exist?(page2.path)).to be_falsey
  end
end
