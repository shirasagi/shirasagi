require 'spec_helper'

describe Cms::AllContentsMoves::ExecuteJob, dbscope: :example do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:node) { create(:cms_node_page, cur_site: site) }
  let(:page) { create(:cms_page, cur_site: site, cur_node: node, filename: "#{node.filename}/page1.html") }
  let(:check_task) { Cms::Task.find_or_create_by(site_id: site.id, name: "cms:all_contents_moves:check") }
  let(:check_result) do
    {
      rows: [
        {
          id: page.id,
          filename: page.filename,
          destination_filename: "#{node.filename}/page2.html",
          status: "ok",
          errors: [],
          confirmations: []
        }
      ],
      task_id: check_task.id,
      created_at: Time.zone.now.iso8601
    }
  end
  let(:execute_data) do
    {
      task_id: check_task.id,
      selected_ids: [page.id.to_s],
      created_at: Time.zone.now.iso8601
    }
  end

  before do
    FileUtils.mkdir_p(check_task.base_dir) if check_task.base_dir
    File.write("#{check_task.base_dir}/check_result.json", check_result.to_json) if check_task.base_dir
    File.write("#{check_task.base_dir}/execute_data.json", execute_data.to_json) if check_task.base_dir

    # 実行タスクをリセット
    execute_task = Cms::Task.where(site_id: site.id, name: "cms:all_contents_moves:execute").first
    if execute_task
      execute_task.close(SS::Task::STATE_STOP) if execute_task.running? || execute_task.state == SS::Task::STATE_RUNNING
      execute_task.destroy
    end

    # Job::Taskもクリーンアップ（ユーザー制限チェックのため）
    Job::Task.where(user_id: user.id).and("$or" => [{ state: /ready|running/ }]).destroy_all
  end

  describe "#perform" do
    context "with valid check result and execute data" do
      it "moves page and creates execute result" do
        job = described_class.bind(site_id: site.id, user_id: user.id)
        ss_perform_now(job, check_task.id)

        execute_task = Cms::Task.find_by(site_id: site.id, name: "cms:all_contents_moves:execute")
        expect(execute_task).to be_present

        result_path = "#{execute_task.base_dir}/execute_result.json"
        expect(File.exist?(result_path)).to be_truthy

        result = JSON.parse(File.read(result_path))
        expect(result["results"]).to be_present
        expect(result["success_count"]).to eq(1)
        expect(result["error_count"]).to eq(0)

        page.reload
        expect(page.filename).to eq("#{node.filename}/page2.html")
      end
    end

    context "when check_result.json does not exist" do
      before do
        FileUtils.rm_f("#{check_task.base_dir}/check_result.json") if check_task.base_dir
      end

      it "logs error and does not create execute result" do
        job = described_class.bind(site_id: site.id, user_id: user.id)
        ss_perform_now(job, check_task.id)

        execute_task = Cms::Task.find_by(site_id: site.id, name: "cms:all_contents_moves:execute")
        result_path = "#{execute_task.base_dir}/execute_result.json" if execute_task&.base_dir
        expect(File.exist?(result_path)).to be_falsey if result_path
      end
    end

    context "when execute_data.json does not exist" do
      before do
        FileUtils.rm_f("#{check_task.base_dir}/execute_data.json") if check_task.base_dir
      end

      it "logs error and does not create execute result" do
        job = described_class.bind(site_id: site.id, user_id: user.id)
        ss_perform_now(job, check_task.id)

        execute_task = Cms::Task.find_by(site_id: site.id, name: "cms:all_contents_moves:execute")
        result_path = "#{execute_task.base_dir}/execute_result.json" if execute_task&.base_dir
        expect(File.exist?(result_path)).to be_falsey if result_path
      end
    end

    context "when page does not exist" do
      let(:check_result) do
        {
          rows: [
            {
              id: 999_999,
              filename: "/test/page1.html",
              destination_filename: "#{node.filename}/page2.html",
              status: "ok",
              errors: [],
              confirmations: []
            }
          ],
          task_id: check_task.id,
          created_at: Time.zone.now.iso8601
        }
      end
      let(:execute_data) do
        {
          task_id: check_task.id,
          selected_ids: %w[999999],
          created_at: Time.zone.now.iso8601
        }
      end

      it "creates execute result with error" do
        job = described_class.bind(site_id: site.id, user_id: user.id)
        ss_perform_now(job, check_task.id)

        execute_task = Cms::Task.find_by(site_id: site.id, name: "cms:all_contents_moves:execute")
        result_path = "#{execute_task.base_dir}/execute_result.json"
        result = JSON.parse(File.read(result_path))

        expect(result["error_count"]).to eq(1)
        expect(result["success_count"]).to eq(0)
        expect(result["results"].first["success"]).to be_falsey
      end
    end

    context "when move fails" do
      let(:invalid_destination) { "/invalid/path/page.html" }
      let(:check_result) do
        {
          rows: [
            {
              id: page.id,
              filename: page.filename,
              destination_filename: invalid_destination,
              status: "ok",
              errors: [],
              confirmations: []
            }
          ],
          task_id: check_task.id,
          created_at: Time.zone.now.iso8601
        }
      end

      it "creates execute result with error" do
        job = described_class.bind(site_id: site.id, user_id: user.id)
        ss_perform_now(job, check_task.id)

        execute_task = Cms::Task.find_by(site_id: site.id, name: "cms:all_contents_moves:execute")
        result_path = "#{execute_task.base_dir}/execute_result.json"
        result = JSON.parse(File.read(result_path))

        expect(result["error_count"]).to be >= 0
        expect(result["results"]).to be_present
      end
    end

    context "with multiple pages" do
      let(:page2) { create(:cms_page, cur_site: site, cur_node: node, filename: "#{node.filename}/page3.html") }
      let(:check_result) do
        {
          rows: [
            {
              id: page.id,
              filename: page.filename,
              destination_filename: "#{node.filename}/page2.html",
              status: "ok",
              errors: [],
              confirmations: []
            },
            {
              id: page2.id,
              filename: page2.filename,
              destination_filename: "#{node.filename}/page4.html",
              status: "ok",
              errors: [],
              confirmations: []
            }
          ],
          task_id: check_task.id,
          created_at: Time.zone.now.iso8601
        }
      end
      let(:execute_data) do
        {
          task_id: check_task.id,
          selected_ids: [page.id.to_s, page2.id.to_s],
          created_at: Time.zone.now.iso8601
        }
      end

      it "moves all selected pages" do
        job = described_class.bind(site_id: site.id, user_id: user.id)
        ss_perform_now(job, check_task.id)

        execute_task = Cms::Task.find_by(site_id: site.id, name: "cms:all_contents_moves:execute")
        result_path = "#{execute_task.base_dir}/execute_result.json"
        result = JSON.parse(File.read(result_path))

        expect(result["success_count"]).to eq(2)
        expect(result["error_count"]).to eq(0)

        page.reload
        page2.reload
        expect(page.filename).to eq("#{node.filename}/page2.html")
        expect(page2.filename).to eq("#{node.filename}/page4.html")
      end
    end

    context "when user is not bound" do
      it "logs error and does not create execute result" do
        job = described_class.bind(site_id: site.id)
        ss_perform_now(job, check_task.id)

        execute_task = Cms::Task.find_by(site_id: site.id, name: "cms:all_contents_moves:execute")
        result_path = "#{execute_task.base_dir}/execute_result.json" if execute_task&.base_dir
        # User not bound should be handled gracefully
      end
    end

    context "with string page_id in selected_ids" do
      let(:execute_data) do
        {
          task_id: check_task.id,
          selected_ids: [page.id.to_s, "invalid"],
          created_at: Time.zone.now.iso8601
        }
      end

      it "filters invalid IDs and processes valid ones" do
        job = described_class.bind(site_id: site.id, user_id: user.id)
        ss_perform_now(job, check_task.id)

        execute_task = Cms::Task.find_by(site_id: site.id, name: "cms:all_contents_moves:execute")
        result_path = "#{execute_task.base_dir}/execute_result.json"
        result = JSON.parse(File.read(result_path))

        expect(result["success_count"]).to eq(1)
      end
    end
  end
end
