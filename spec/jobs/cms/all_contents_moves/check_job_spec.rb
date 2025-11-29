require 'spec_helper'

describe Cms::AllContentsMoves::CheckJob, dbscope: :example do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:node) { create(:cms_node_page, cur_site: site) }
  let(:page) { create(:cms_page, cur_site: site, cur_node: node, filename: "#{node.filename}/page1.html") }

  describe ".valid_csv?" do
    context "with valid CSV file" do
      let(:csv_content) do
        page_id_header = I18n.t("all_content.page_id")
        filename_header = I18n.t("cms.all_contents_moves.destination_filename")
        CSV.generate(headers: true) do |csv|
          csv << [page_id_header, filename_header]
          csv << [page.id, "#{node.filename}/page2.html"]
        end
      end
      let(:csv_file) do
        Fs::UploadedFile.create_from_file(
          tmpfile(extname: ".csv") { |f| f.write(csv_content) },
          basename: "spec"
        )
      end

      it "returns true" do
        expect(described_class.valid_csv?(csv_file)).to be_truthy
      end
    end

    context "with invalid CSV file (missing headers)" do
      let(:csv_content) do
        CSV.generate(headers: true) do |csv|
          csv << %w[invalid headers]
          csv << [page.id, "#{node.filename}/page2.html"]
        end
      end
      let(:csv_file) do
        Fs::UploadedFile.create_from_file(
          tmpfile(extname: ".csv") { |f| f.write(csv_content) },
          basename: "spec"
        )
      end

      it "returns false" do
        expect(described_class.valid_csv?(csv_file)).to be_falsey
      end
    end

    context "with non-CSV file" do
      let(:pdf_file) do
        Fs::UploadedFile.create_from_file(
          Rails.root.join('spec/fixtures/ss/shirasagi.pdf'),
          basename: "spec"
        )
      end

      it "returns false" do
        expect(described_class.valid_csv?(pdf_file)).to be_falsey
      end
    end
  end

  describe "#perform" do
    let(:csv_content) do
      page_id_header = I18n.t("all_content.page_id")
      filename_header = I18n.t("cms.all_contents_moves.destination_filename")
      CSV.generate(headers: true) do |csv|
        csv << [page_id_header, filename_header]
        csv << [page.id, "#{node.filename}/page2.html"]
      end
    end
    let(:ss_file) do
      SS::TempFile.create_empty!(name: "#{unique_id}.csv", filename: "#{unique_id}.csv", content_type: 'text/csv') do |file|
        ::File.write(file.path, csv_content)
      end
    end

    context "with valid page" do
      it "creates check result with ok status" do
        job = described_class.bind(site_id: site.id, user_id: user.id)
        ss_perform_now(job, ss_file.id)

        task = Cms::Task.find_by(site_id: site.id, name: "cms:all_contents_moves:check")
        expect(task).to be_present

        result_path = "#{task.base_dir}/check_result.json"
        expect(File.exist?(result_path)).to be_truthy

        result = JSON.parse(File.read(result_path))
        expect(result["rows"]).to be_present
        expect(result["rows"].first["status"]).to eq("ok")
        expect(result["rows"].first["id"]).to eq(page.id)
      end
    end

    context "with blank page_id" do
      let(:csv_content) do
        page_id_header = I18n.t("all_content.page_id")
        filename_header = I18n.t("cms.all_contents_moves.destination_filename")
        CSV.generate(headers: true) do |csv|
          csv << [page_id_header, filename_header]
          csv << ["", "#{node.filename}/page2.html"]
        end
      end

      it "creates check result with error status" do
        job = described_class.bind(site_id: site.id, user_id: user.id)
        ss_perform_now(job, ss_file.id)

        task = Cms::Task.find_by(site_id: site.id, name: "cms:all_contents_moves:check")
        result_path = "#{task.base_dir}/check_result.json"
        result = JSON.parse(File.read(result_path))

        expect(result["rows"].first["status"]).to eq("error")
        expect(result["rows"].first["errors"]).to be_present
        expect(result["rows"].first["errors"]).to include(I18n.t("cms.all_contents_moves.errors.page_id_blank"))
      end
    end

    context "with invalid page_id format" do
      let(:csv_content) do
        page_id_header = I18n.t("all_content.page_id")
        filename_header = I18n.t("cms.all_contents_moves.destination_filename")
        CSV.generate(headers: true) do |csv|
          csv << [page_id_header, filename_header]
          csv << ["invalid", "#{node.filename}/page2.html"]
        end
      end

      it "creates check result with error status" do
        job = described_class.bind(site_id: site.id, user_id: user.id)
        ss_perform_now(job, ss_file.id)

        task = Cms::Task.find_by(site_id: site.id, name: "cms:all_contents_moves:check")
        result_path = "#{task.base_dir}/check_result.json"
        result = JSON.parse(File.read(result_path))

        expect(result["rows"].first["status"]).to eq("error")
        expect(result["rows"].first["errors"]).to be_present
        expect(result["rows"].first["errors"]).to include(I18n.t("cms.all_contents_moves.errors.invalid_page_id"))
      end
    end

    context "with non-existent page_id" do
      let(:csv_content) do
        page_id_header = I18n.t("all_content.page_id")
        filename_header = I18n.t("cms.all_contents_moves.destination_filename")
        CSV.generate(headers: true) do |csv|
          csv << [page_id_header, filename_header]
          csv << [999_999, "#{node.filename}/page2.html"]
        end
      end

      it "creates check result with error status" do
        job = described_class.bind(site_id: site.id, user_id: user.id)
        ss_perform_now(job, ss_file.id)

        task = Cms::Task.find_by(site_id: site.id, name: "cms:all_contents_moves:check")
        result_path = "#{task.base_dir}/check_result.json"
        result = JSON.parse(File.read(result_path))

        expect(result["rows"].first["status"]).to eq("error")
        expect(result["rows"].first["errors"]).to be_present
        expect(result["rows"].first["errors"]).to include(I18n.t("cms.all_contents_moves.errors.page_not_found"))
      end
    end

    context "with same filename" do
      let(:csv_content) do
        page_id_header = I18n.t("all_content.page_id")
        filename_header = I18n.t("cms.all_contents_moves.destination_filename")
        CSV.generate(headers: true) do |csv|
          csv << [page_id_header, filename_header]
          csv << [page.id, page.filename]
        end
      end

      it "creates check result with error status" do
        job = described_class.bind(site_id: site.id, user_id: user.id)
        ss_perform_now(job, ss_file.id)

        task = Cms::Task.find_by(site_id: site.id, name: "cms:all_contents_moves:check")
        result_path = "#{task.base_dir}/check_result.json"
        result = JSON.parse(File.read(result_path))

        expect(result["rows"].first["status"]).to eq("error")
        expect(result["rows"].first["errors"]).to be_present
        expect(result["rows"].first["errors"]).to include(I18n.t("cms.all_contents_moves.errors.same_filename"))
      end
    end

    context "with destination filename without extension" do
      let(:csv_content) do
        page_id_header = I18n.t("all_content.page_id")
        filename_header = I18n.t("cms.all_contents_moves.destination_filename")
        CSV.generate(headers: true) do |csv|
          csv << [page_id_header, filename_header]
          csv << [page.id, "#{node.filename}/page2"]
        end
      end

      it "adds .html extension automatically" do
        job = described_class.bind(site_id: site.id, user_id: user.id)
        ss_perform_now(job, ss_file.id)

        task = Cms::Task.find_by(site_id: site.id, name: "cms:all_contents_moves:check")
        result_path = "#{task.base_dir}/check_result.json"
        result = JSON.parse(File.read(result_path))

        expect(result["rows"].first["destination_filename"]).to eq("#{node.filename}/page2.html")
      end
    end

    context "with linking pages" do
      let(:linking_page) { create(:cms_page, cur_site: site, cur_node: node, html: "<a href=\"#{page.url}\">link</a>") }

      before do
        linking_page
      end

      it "creates check result with confirmation status" do
        job = described_class.bind(site_id: site.id, user_id: user.id)
        ss_perform_now(job, ss_file.id)

        task = Cms::Task.find_by(site_id: site.id, name: "cms:all_contents_moves:check")
        result_path = "#{task.base_dir}/check_result.json"
        result = JSON.parse(File.read(result_path))

        expect(result["rows"].first["status"]).to eq("confirmation")
        expect(result["rows"].first["confirmations"]).to be_present
      end
    end

    context "with branch page" do
      let(:branch_page) do
        page = create(:cms_page, cur_site: site, cur_node: node, filename: "#{node.filename}/branch.html")
        page.master = create(:cms_page, cur_site: site, cur_node: node, filename: "#{node.filename}/master.html")
        page.save!
        page
      end
      let(:csv_content) do
        page_id_header = I18n.t("all_content.page_id")
        filename_header = I18n.t("cms.all_contents_moves.destination_filename")
        CSV.generate(headers: true) do |csv|
          csv << [page_id_header, filename_header]
          csv << [branch_page.id, "#{node.filename}/page2.html"]
        end
      end

      it "creates check result with error status" do
        job = described_class.bind(site_id: site.id, user_id: user.id)
        ss_perform_now(job, ss_file.id)

        task = Cms::Task.find_by(site_id: site.id, name: "cms:all_contents_moves:check")
        result_path = "#{task.base_dir}/check_result.json"
        result = JSON.parse(File.read(result_path))

        expect(result["rows"].first["status"]).to eq("error")
        expect(result["rows"].first["errors"]).to be_present
        expect(result["rows"].first["errors"]).to include(I18n.t("cms.all_contents_moves.errors.branch_page_can_not_move"))
      end
    end
  end
end
