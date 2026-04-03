require 'spec_helper'

describe Cms::ConsistencyCheckJob, dbscope: :example do
  let!(:site) { cms_site }

  let!(:facility_search) { create :facility_node_search }
  let!(:facility_node) { create :facility_node_node, cur_node: facility_search }
  let!(:facility_page1) { create :facility_node_page, cur_node: facility_node }
  let!(:facility_page2) { create :facility_node_page, cur_node: facility_node }
  let!(:facility_page3) { create :facility_node_page, cur_node: facility_node }

  before { Fs.rm_rf site.path }
  after { Fs.rm_rf site.path }

  def generate_htmls
    expect { Cms::Node::GenerateJob.bind(site_id: site).perform_now }.to output.to_stdout
    Job::Log.all.destroy_all

    expect(File.exist?(facility_search.path)).to be true
    expect(File.exist?(facility_node.path)).to be true
    # facility_node_page は　serve_static_file? が false のため、書き出してもファイルは作成されない
    expect(File.exist?(facility_page1.path)).to be_falsey
    expect(File.exist?(facility_page2.path)).to be_falsey
    expect(File.exist?(facility_page3.path)).to be_falsey
  end

  def set_improper_htmls
    facility_page1.state = "closed"
    facility_page1.update!
    ::FileUtils.mkdir_p(facility_page1.path)
    ::FileUtils.touch("#{facility_page1.path}/index.html")

    facility_page2.destroy!
    ::FileUtils.mkdir_p(facility_page2.path)
    ::FileUtils.touch("#{facility_page2.path}/index.html")

    # serve_static_file? is false
    ::FileUtils.mkdir_p(facility_page3.path)
    ::FileUtils.touch("#{facility_page3.path}/index.html")

    expect(File.exist?(facility_page1.path)).to be true
    expect(File.exist?(facility_page2.path)).to be true
    expect(File.exist?(facility_page3.path)).to be true
  end

  context "no errors" do
    it "#perform" do
      generate_htmls

      expectation = expect { described_class.bind(site_id: site).perform_now(repair: true) }
      expectation.not_to output(include("removed")).to_stdout

      log = Job::Log.first
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
    end
  end

  context "errors exists" do
    it "#perform" do
      generate_htmls
      set_improper_htmls

      expectation = expect { described_class.bind(site_id: site).perform_now(repair: true) }
      expectation.to output(
        include(
          site.name,
          "#{facility_page1.path}/index.html: removed",
          "#{facility_page2.path}/index.html: removed",
          "#{facility_page3.path}/index.html: removed"
        )).to_stdout

      expect(File.exist?("#{facility_page1.path}/index.html")).to be false
      expect(File.exist?("#{facility_page2.path}/index.html")).to be false
      expect(File.exist?("#{facility_page3.path}/index.html")).to be false

      log = Job::Log.first
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
    end
  end
end
