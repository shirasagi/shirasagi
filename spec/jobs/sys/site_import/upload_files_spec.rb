require 'spec_helper'

describe Sys::SiteImportJob, dbscope: :example do
  let!(:source_site) { create :cms_site_unique }
  let!(:node1) { create :uploader_node_file, cur_site: source_site }
  let!(:node2) { create :uploader_node_file, cur_site: source_site }
  let!(:node3) { create :uploader_node_file, cur_node: node2, cur_site: source_site }

  let!(:filename1) { "#{unique_id}.png" }
  let!(:file1) do
    path = "#{node1.path}/#{filename1}"
    ::Fs.mkdir_p(::File.dirname(path))
    ::Fs.cp("#{Rails.root}/spec/fixtures/ss/logo.png", path)
    path
  end
  let!(:filename2) { "__#{unique_id}__.jpg" }
  let!(:file2) do
    path = "#{node2.path}/#{filename2}"
    ::Fs.mkdir_p(::File.dirname(path))
    ::Fs.cp("#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg", path)
    path
  end
  let!(:filename3) { "#{unique_id}.pdf" }
  let!(:file3) do
    path = "#{node3.path}/#{filename3}"
    ::Fs.mkdir_p(::File.dirname(path))
    ::Fs.cp("#{Rails.root}/spec/fixtures/ss/shirasagi.pdf", path)
    path
  end

  let!(:file_path) do
    save_export_root = Sys::SiteExportJob.export_root
    Sys::SiteExportJob.export_root = tmpdir

    begin
      job = ::Sys::SiteExportJob.new
      job.bind("site_id" => source_site.id).perform
      output_zip = job.instance_variable_get(:@output_zip)

      output_zip
    ensure
      Sys::SiteExportJob.export_root = save_export_root
    end
  end

  describe "#perform" do
    let!(:destination_site) { create :cms_site_unique }

    it do
      job = ::Sys::SiteImportJob.new
      job.bind("site_id" => destination_site.id).perform(file_path)

      expect(Uploader::Node::File.site(destination_site).count).to eq 3
      dest_node1 = Uploader::Node::File.site(destination_site).where(filename: node1.filename).first
      dest_node2 = Uploader::Node::File.site(destination_site).where(filename: node2.filename).first
      dest_node3 = Uploader::Node::File.site(destination_site).where(filename: node3.filename).first
      expect(dest_node1).to be_present
      expect(dest_node2).to be_present
      expect(dest_node3).to be_present

      path = "#{dest_node1.path}/#{filename1}"
      expect(Fs.exist?(path)).to be_truthy
      expect(Fs.binread(path)).to eq Fs.binread(file1)

      path = "#{dest_node2.path}/#{filename2}"
      expect(Fs.exist?(path)).to be_truthy
      expect(Fs.binread(path)).to eq Fs.binread(file2)

      path = "#{dest_node3.path}/#{filename3}"
      expect(Fs.exist?(path)).to be_truthy
      expect(Fs.binread(path)).to eq Fs.binread(file3)
    end
  end
end
