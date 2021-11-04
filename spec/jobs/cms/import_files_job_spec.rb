require 'spec_helper'

describe Cms::ImportFilesJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:in_file) { Rack::Test::UploadedFile.new("#{::Rails.root}/spec/fixtures/cms/import/site.zip", nil, true) }
  let!(:name) { "sample-#{unique_id}" }
  let!(:import_job_file) do
    create(:cms_import_job_file, site: site, name: name, basename: name, in_file: in_file)
  end

  describe "#perform" do
    before do
      expected_files = [ "#{name}/index.html", "#{name}/article/page.html", "#{name}/css/style.css", "#{name}/img/logo.jpg" ]
      expect do
        described_class.bind(site_id: site).perform_now
      end.to output(include(*expected_files)).to_stdout
    end

    it do
      log = Job::Log.first
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).not_to include(/INFO -- : .* error:/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)

      pages = Cms::ImportPage.all
      nodes = Cms::Node::ImportNode.all
      expect(pages.pluck(:name).sort).to eq %w(index.html page.html)
      expect(pages.pluck(:filename).sort).to include("#{name}/article/page.html", "#{name}/index.html")
      expect(nodes.pluck(:name).sort).to include("article", "css", "img", name)
      expect(nodes.pluck(:filename).sort).to include(name, "#{name}/article", "#{name}/css", "#{name}/img")

      pages.each do |page|
        expect(page.html.present?).to eq true
        page.html.scan(/(href|src)="\/(.+?)"/) do
          path = $2
          expect(path =~ /#{::Regexp.escape(name)}\//).to eq 0
        end
      end

      css_node = nodes.find_by(filename: "#{name}/css")
      expect(::File.exist?("#{css_node.path}/style.css")).to be_truthy

      img_node = nodes.find_by(filename: "#{name}/img")
      expect(::File.exist?("#{img_node.path}/logo.jpg")).to be_truthy

      expect(Cms::ImportJobFile.count).to eq 0
    end
  end
end
