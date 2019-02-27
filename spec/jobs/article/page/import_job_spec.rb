require 'spec_helper'

describe Article::Page::ImportJob, dbscope: :example do
  let!(:site) { cms_site }

  describe ".valid_csv?" do
    context "with csv file" do
      let(:path) { "#{Rails.root}/spec/fixtures/article/article_import_test_1.csv" }

      it do
        Fs::UploadedFile.create_from_file(path, basename: "spec") do |file|
          expect(Article::Page::ImportJob.valid_csv?(file)).to be_truthy
        end
      end
    end

    context "with pdf file" do
      let(:path) { "#{Rails.root}/spec/fixtures/ss/shirasagi.pdf" }

      it do
        Fs::UploadedFile.create_from_file(path, basename: "spec") do |file|
          expect(Article::Page::ImportJob.valid_csv?(file)).to be_falsey
        end
      end
    end
  end

  describe "#perform" do
    let(:path) { "#{Rails.root}/spec/fixtures/article/article_import_test_1.csv" }
    let(:ss_file) do
      SS::TempFile.create_empty!(name: "#{unique_id}.csv", filename: "#{unique_id}.csv", content_type: 'text/csv') do |file|
        ::FileUtils.cp(path, file.path)
      end
    end
    let(:node) do
      create :article_node_page, cur_site: site
    end

    before do
      job = Article::Page::ImportJob.bind(site_id: site, node_id: node, user_id: cms_user)
      job.perform_now(ss_file.id)
    end

    it do
      Job::Log.first.tap do |log|
        expect(log.logs).to include(include("INFO -- : Started Job"))
        expect(log.logs).to include(include("INFO -- : Completed Job"))
      end

      expect(Article::Page.site(site).count).to eq 2
      expect(Article::Page.site(site).where(filename: "#{node.filename}/test_1.html")).to be_present
      expect(Article::Page.site(site).where(filename: "#{node.filename}/test_2.html")).to be_present
    end
  end
end
