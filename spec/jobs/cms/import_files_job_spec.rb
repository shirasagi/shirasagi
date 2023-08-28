require 'spec_helper'

describe Cms::ImportFilesJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:import_job_file) do
    create(:cms_import_job_file, cur_site: site, cur_node: node,
      name: dir, basename: dir, in_file: in_file)
  end

  shared_examples "perform import from zip" do
    let(:expected_files) do
      %w(index.html article/page.html css/style.css img/logo.jpg).map { |file| ::File.join(root, file) }
    end

    it do
      expectation = expect { described_class.bind(job_binding).perform_now }
      expectation.to output(include(*expected_files)).to_stdout

      log = Job::Log.first
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).not_to include(/INFO -- : .* error:/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)

      pages = Cms::ImportPage.all
      nodes = Cms::Node::ImportNode.all
      expect(pages.pluck(:name).sort).to eq %w(index.html page.html)
      expect(pages.pluck(:filename).sort).to include("#{root}/article/page.html", "#{root}/index.html")
      expect(nodes.pluck(:name).sort).to include("article", "css", "img", dir)
      expect(nodes.pluck(:filename).sort).to include(root, "#{root}/article", "#{root}/css", "#{root}/img")

      pages.each do |page|
        expect(page.html.present?).to eq true
        page.html.scan(/(href|src)="\/(.+?)"/) do
          path = $2
          expect(path =~ /#{::Regexp.escape(root)}\//).to eq 0
        end
      end

      css_node = nodes.find_by(filename: "#{root}/css")
      expect(::File.exist?("#{css_node.path}/style.css")).to be_truthy

      img_node = nodes.find_by(filename: "#{root}/img")
      expect(::File.exist?("#{img_node.path}/logo.jpg")).to be_truthy

      expect(Cms::ImportJobFile.count).to eq 0
    end
  end

  context "root" do
    let(:node) { nil }
    let(:job_binding) { { site_id: site.id } }

    context "zip file contain root directory" do
      let(:in_file) { Rack::Test::UploadedFile.new("#{::Rails.root}/spec/fixtures/cms/import/site.zip", nil, true) }
      let(:dir) { "site" }
      let(:root) { "site" }

      it_behaves_like "perform import from zip"
    end

    context "zip file not contain root directory" do
      let(:in_file) { Rack::Test::UploadedFile.new("#{::Rails.root}/spec/fixtures/cms/import/site2.zip", nil, true) }
      let(:dir) { "site2" }
      let(:root) { "site2" }

      it_behaves_like "perform import from zip"
    end
  end

  context "node given" do
    let!(:node) { create :article_node_page, cur_site: site }
    let(:job_binding) { { site_id: site.id, node_id: node.id } }

    context "zip file contain root directory" do
      let(:in_file) { Rack::Test::UploadedFile.new("#{::Rails.root}/spec/fixtures/cms/import/site.zip", nil, true) }
      let(:dir) { "site" }
      let(:root) { "#{node.filename}/#{dir}" }

      it_behaves_like "perform import from zip"
    end

    context "zip file not contain root directory" do
      let(:in_file) { Rack::Test::UploadedFile.new("#{::Rails.root}/spec/fixtures/cms/import/site2.zip", nil, true) }
      let(:dir) { "site2" }
      let(:root) { "#{node.filename}/#{dir}" }

      it_behaves_like "perform import from zip"
    end

    context "zip slip" do
      let!(:zip_file) do
        file = tmpfile(extname: ".zip")
        Zip::File.open(file, Zip::File::CREATE) do |zip|
          zip.mkdir("../../#{dir}")
          zip.get_output_stream("../../#{dir}/index.html") do |f|
            IO.copy_stream("#{Rails.root}/db/seeds/demo/pages/docs/tenkyo.html", f)
          end

          zip.mkdir("../../#{dir}/article")
          zip.get_output_stream("../../#{dir}/article/page.html") do |f|
            IO.copy_stream("#{Rails.root}/db/seeds/demo/pages/docs/tenkyo.html", f)
          end

          zip.mkdir("../../#{dir}/css")
          zip.get_output_stream("../../#{dir}/css/style.scss") do |f|
            IO.copy_stream("#{Rails.root}/db/seeds/demo/files/css/style.scss", f)
          end

          zip.mkdir("../../#{dir}/img")
          zip.get_output_stream("../../#{dir}/img/logo.png") do |f|
            IO.copy_stream("#{Rails.root}/spec/fixtures/ss/logo.png", f)
          end
        end
        file
      end
      let(:in_file) { Rack::Test::UploadedFile.new(zip_file, nil, true) }
      let(:dir) { "site3" }
      let(:root) { "#{node.filename}/#{dir}" }

      it do
        expectation = expect { described_class.bind(job_binding).perform_now }
        expectation.to output.to_stdout

        log = Job::Log.first
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).not_to include(/INFO -- : .* error:/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)

        expect(Cms::ImportPage.all.count).to eq 0
        expect(Cms::Node::ImportNode.all.count).to eq 1
      end
    end
  end
end
