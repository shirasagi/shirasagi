require 'spec_helper'
require 'rake'

describe Sys::SiteExportJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:subsite1) do
    create(:cms_site_subdir, domains: site.domains, parent: site, subdir: "sub1", group_ids: site.group_ids)
  end
  let!(:subsite2) do
    create(:cms_site_subdir, domains: site.domains, parent: site, subdir: "sub2", group_ids: site.group_ids)
  end

  let(:root_node) { create :cms_node, cur_site: site, filename: "node" }
  let(:root_page1) { create :cms_page, cur_site: site, filename: "root.html" }
  let(:root_page2) { create :cms_page, cur_site: site, cur_node: root_node, basename: "root.html" }

  let(:sub1_node) { create :cms_node, cur_site: subsite1, filename: "node" }
  let(:sub1_page1) { create :cms_page, cur_site: subsite1, filename: "sub1.html" }
  let(:sub1_page2) { create :cms_page, cur_site: subsite1, cur_node: sub1_node, basename: "sub1.html" }

  let(:sub2_node) { create :cms_node, cur_site: subsite2, filename: "node" }
  let(:sub2_page1) { create :cms_page, cur_site: subsite2, filename: "sub2.html" }
  let(:sub2_page2) { create :cms_page, cur_site: subsite2, cur_node: sub2_node, basename: "sub2.html" }

  around do |example|
    tmpdir = ::Dir.mktmpdir(unique_id, "#{Rails.root}/tmp")
    ::Dir.mkdir_p(tmpdir) if !::Dir.exist?(tmpdir)

    Sys::SiteExportJob.export_root = tmpdir

    example.run

    FileUtils.rm_rf(tmpdir)
  end

  def execute(site)
    job = ::Sys::SiteExportJob.new
    job.bind("site_id" => site.id).perform
    job.instance_variable_get(:@output_zip)
  end

  before do
    FileUtils.rm_rf(site.path)
    root_node
    root_page1
    root_page2
    sub1_node
    sub1_page1
    sub1_page2
    sub2_node
    sub2_page1
    sub2_page2
  end

  context 'site export' do
    it do
      zip_path = execute(site)
      zip = Zip::File.open(zip_path)
      entry_names = zip.entries.map(&:name)

      expect(entry_names).to include(/root\.html/)
      expect(entry_names).not_to include(/sub1\.html/)
      expect(entry_names).not_to include(/sub2\.html/)
    end
  end

  context 'subsite1 export' do
    it do
      zip_path = execute(subsite1)
      zip = Zip::File.open(zip_path)
      entry_names = zip.entries.map(&:name)

      expect(entry_names).not_to include(/root\.html/)
      expect(entry_names).to include(/sub1\.html/)
      expect(entry_names).not_to include(/sub2\.html/)
    end
  end

  context 'subsite2 export' do
    it do
      zip_path = execute(subsite2)
      zip = Zip::File.open(zip_path)
      entry_names = zip.entries.map(&:name)

      expect(entry_names).not_to include(/root\.html/)
      expect(entry_names).not_to include(/sub1\.html/)
      expect(entry_names).to include(/sub2\.html/)
    end
  end
end
