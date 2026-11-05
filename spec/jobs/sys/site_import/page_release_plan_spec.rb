require 'spec_helper'

describe Sys::SiteImportJob, dbscope: :example do
  let!(:source_site) { create :cms_site_unique }
  let!(:layout) { create_cms_layout cur_site: source_site }
  let!(:node) { create :article_node_page, cur_site: source_site, layout: layout }

  let!(:now) { Time.zone.now }
  let!(:page1) { create :article_page, cur_site: source_site, cur_node: node, layout: layout, release_date: now + 1.hour, state: "public" }
  let!(:page2) { create :article_page, cur_site: source_site, cur_node: node, layout: layout, release_date: now + 1.hour, state: "closed" }
  let!(:page3) { create :article_page, cur_site: source_site, cur_node: node, layout: layout, close_date: now + 1.hour, state: "public" }
  let!(:page4) { create :article_page, cur_site: source_site, cur_node: node, layout: layout, close_date: now + 1.hour, state: "closed" }

  let(:dest_site) { create :cms_site_unique }
  let(:dest_node) { Article::Node::Page.site(dest_site).where(filename: node.filename).first }
  let(:dest_page1) { Article::Page.site(dest_site).where(filename: page1.filename).first }
  let(:dest_page2) { Article::Page.site(dest_site).where(filename: page2.filename).first }
  let(:dest_page3) { Article::Page.site(dest_site).where(filename: page3.filename).first }
  let(:dest_page4) { Article::Page.site(dest_site).where(filename: page4.filename).first }

  let(:file_path) do
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

  context "#perform now" do
    it do
      expect(page1.public?).to be_falsey
      expect(page2.public?).to be_falsey
      expect(page3.public?).to be_truthy
      expect(page4.public?).to be_falsey

      job = Sys::SiteImportJob.new
      job.bind("site_id" => dest_site.id).perform(file_path)

      expect(dest_node).to be_present
      expect(dest_page1).to be_present
      expect(dest_page2).to be_present
      expect(dest_page3).to be_present
      expect(dest_page4).to be_present

      expect(dest_page1.public?).to be_falsey
      expect(dest_page2.public?).to be_falsey
      expect(dest_page3.public?).to be_truthy
      expect(dest_page4.public?).to be_falsey

      expect(dest_page1.state).to eq page1.state
      expect(dest_page1.release_date.change(sec: 0)).to eq page1.release_date.change(sec: 0)
      expect(dest_page2.state).to eq page2.state
      expect(dest_page2.release_date.change(sec: 0)).to eq page2.release_date.change(sec: 0)
      expect(dest_page3.state).to eq page3.state
      expect(dest_page3.close_date.change(sec: 0)).to eq page3.close_date.change(sec: 0)
      expect(dest_page4.state).to eq page4.state
      expect(dest_page4.close_date).to eq nil
    end
  end

  context "#perform 1 day later" do
    it do
      Timecop.travel(1.day) do
        expect(page1.public?).to be_falsey
        expect(page2.public?).to be_falsey
        expect(page3.public?).to be_truthy
        expect(page4.public?).to be_falsey

        job = Sys::SiteImportJob.new
        job.bind("site_id" => dest_site.id).perform(file_path)

        expect(dest_node).to be_present
        expect(dest_page1).to be_present
        expect(dest_page2).to be_present
        expect(dest_page3).to be_present
        expect(dest_page4).to be_present

        expect(dest_page1.public?).to be_falsey
        expect(dest_page2.public?).to be_falsey
        expect(dest_page3.public?).to be_falsey
        expect(dest_page4.public?).to be_falsey

        expect(dest_page1.state).to eq "ready"
        expect(dest_page1.release_date.change(sec: 0)).to eq page1.release_date.change(sec: 0)
        expect(dest_page2.state).to eq "closed"
        expect(dest_page2.release_date.change(sec: 0)).to eq page2.release_date.change(sec: 0)
        expect(dest_page3.state).to eq "closed"
        expect(dest_page3.close_date).to eq nil
        expect(dest_page4.state).to eq "closed"
        expect(dest_page4.close_date).to eq nil

        # サイトインポート完了後にページ公開が定期実行されたタイミングで dest_page1 (state ready) が公開される
        job = Cms::Page::ReleaseJob
        job.bind("site_id" => dest_site.id).perform_now
        dest_page1.reload
        dest_page2.reload
        dest_page3.reload
        dest_page4.reload

        expect(dest_page1.public?).to be_truthy
        expect(dest_page2.public?).to be_falsey
        expect(dest_page3.public?).to be_falsey
        expect(dest_page4.public?).to be_falsey

        expect(dest_page1.state).to eq "public"
        expect(dest_page1.release_date).to eq nil
        expect(dest_page2.state).to eq "closed"
        expect(dest_page2.release_date.change(sec: 0)).to eq page2.release_date.change(sec: 0)
        expect(dest_page3.state).to eq "closed"
        expect(dest_page3.close_date).to eq nil
        expect(dest_page4.state).to eq "closed"
        expect(dest_page4.close_date).to eq nil
      end
    end
  end
end
