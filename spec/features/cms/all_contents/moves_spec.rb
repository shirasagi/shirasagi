require 'spec_helper'

describe "cms_all_contents_moves", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:layout) { create(:cms_layout, cur_site: site) }
  let!(:node_src) { create(:article_node_page, cur_site: site, layout_id: layout.id, group_ids: [cms_group.id]) }
  let!(:node_dst) { create(:article_node_page, cur_site: site, layout_id: layout.id, group_ids: [cms_group.id]) }

  let!(:page1) do
    create(:article_page, cur_site: site, cur_node: node_src, layout_id: layout.id, group_ids: [cms_group.id])
  end
  let!(:page2) do
    create(:article_page, cur_site: site, cur_node: node_src, layout_id: layout.id, group_ids: [cms_group.id])
  end

  let(:csv_headers) { I18n.t('cms.all_contents_moves.csv_headers') }

  before { login_cms_user }

  def build_csv(*pages_with_destinations)
    csv = CSV.generate do |csv|
      csv << [csv_headers[:page_id], csv_headers[:name], csv_headers[:index_name], csv_headers[:filename],
              csv_headers[:layout], csv_headers[:order], csv_headers[:keywords], csv_headers[:description],
              csv_headers[:summary_html], csv_headers[:category], csv_headers[:parent_crumb_urls],
              csv_headers[:contact_state], csv_headers[:contact_group], csv_headers[:contact_group_contact],
              csv_headers[:contact_group_relation], csv_headers[:contact_group_name], csv_headers[:contact_charge],
              csv_headers[:contact_tel], csv_headers[:contact_fax], csv_headers[:contact_email],
              csv_headers[:contact_postal_code], csv_headers[:contact_address],
              csv_headers[:contact_link_url], csv_headers[:contact_link_name],
              csv_headers[:contact_sub_groups], csv_headers[:group_ids]]
      pages_with_destinations.each do |page_item, destination|
        csv << [page_item.id, nil, nil, destination]
      end
    end
    "\uFEFF" + csv
  end

  def create_csv_file(csv_data)
    SS::TmpDir.tmpfile(extname: ".csv", binary: true) do |f|
      f.write csv_data
    end
  end

  describe "initial page" do
    it "displays the moves tab and settings" do
      visit cms_all_contents_moves_path(site: site)

      expect(page).to have_css(".cms-tabs .current", text: I18n.t("cms.all_content.moves_tab"))
      expect(page).to have_css("#cms-all-contents-move-settings")
      expect(page).to have_css("input[type='file']")
      expect(page).to have_content(I18n.t("cms.all_contents_moves.description"))
      expect(page).to have_content(I18n.t("cms.all_contents_moves.branch_page_notice"))
    end
  end

  describe "template download" do
    it "downloads CSV template containing existing pages" do
      # Exporterを直接テストする（send_enumのストリーミングレスポンスはCapybaraで取得困難なため）
      exporter = Cms::AllContentsMoveExporter.new(site: site)
      csv_source = exporter.enum_csv(encoding: "UTF-8").to_a.join
      csv_source.force_encoding("UTF-8")
      csv_source = csv_source[1..-1]
      SS::Csv.open(StringIO.new(csv_source)) do |csv|
        table = csv.read

        expect(table.headers).to include(csv_headers[:page_id], csv_headers[:filename], csv_headers[:name])
        ids = table.map { |row| row[csv_headers[:page_id]].to_i }
        expect(ids).to include(page1.id, page2.id)
      end
    end
  end

  describe "CSV import and check" do
    context "with valid CSV" do
      let(:dst1) { "#{node_dst.filename}/#{page1.basename}" }
      let(:dst2) { "#{node_dst.filename}/#{page2.basename}" }
      let(:csv_data) { build_csv([page1, dst1], [page2, dst2]) }

      it "enqueues check job" do
        csv_file = create_csv_file(csv_data)

        visit cms_all_contents_moves_path(site: site)
        within "form" do
          attach_file "item[in_file]", csv_file
          click_on I18n.t("cms.all_contents_moves.read_csv")
        end
        wait_for_notice I18n.t('ss.notice.started_import')

        expect(enqueued_jobs.length).to eq 1
        expect(enqueued_jobs.first[:job]).to eq Cms::AllContents::MoveCheckJob
      end
    end

    context "with invalid file (not CSV)" do
      it "shows error" do
        visit cms_all_contents_moves_path(site: site)
        within "form" do
          attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/ss/logo.png"
          click_on I18n.t("cms.all_contents_moves.read_csv")
        end

        expect(page).to have_css("#errorExplanation", text: I18n.t("errors.messages.invalid_csv"))
      end
    end
  end

  describe "full move workflow" do
    let(:dst1) { "#{node_dst.filename}/#{page1.basename}" }
    let(:dst2) { "#{node_dst.filename}/#{page2.basename}" }
    let(:csv_data) { build_csv([page1, dst1], [page2, dst2]) }

    around do |example|
      save_config = SS.config.replace_value_at(:cms, 'replace_urls_after_move', false)
      perform_enqueued_jobs { example.run }
      SS.config.replace_value_at(:cms, 'replace_urls_after_move', save_config)
    end

    it "checks CSV, shows results, executes move, and shows completion" do
      csv_file = create_csv_file(csv_data)

      # Step 1: Upload CSV
      visit cms_all_contents_moves_path(site: site)
      within "form" do
        attach_file "item[in_file]", csv_file
        click_on I18n.t("cms.all_contents_moves.read_csv")
      end

      # Step 2: Check result page should appear
      expect(page).to have_css("#cms-all-contents-move-result", wait: 30)
      expect(page).to have_css(".status-ok", text: "OK")
      expect(page).to have_css("input[name='ids[]']", count: 2)

      # Step 3: Execute move (confirm dialog)
      accept_confirm do
        within "form" do
          click_on I18n.t("cms.all_contents_moves.execute_move")
        end
      end

      # Step 4: Completion page should appear
      expect(page).to have_css("#cms-all-contents-move-completed", wait: 30)
      expect(page).to have_css(".status-ok", text: "OK")

      # Verify pages have been moved
      page1.reload
      expect(page1.filename).to eq dst1

      page2.reload
      expect(page2.filename).to eq dst2
    end
  end

  describe "partial move with mixed results" do
    let(:dst1) { "#{node_dst.filename}/#{page1.basename}" }
    let(:csv_data) { build_csv([page1, dst1], [page2, "nonexistent/page.html"]) }

    around do |example|
      save_config = SS.config.replace_value_at(:cms, 'replace_urls_after_move', false)
      perform_enqueued_jobs { example.run }
      SS.config.replace_value_at(:cms, 'replace_urls_after_move', save_config)
    end

    it "moves only the valid page and leaves the error page unchanged" do
      original_page2_filename = page2.filename
      csv_file = create_csv_file(csv_data)

      visit cms_all_contents_moves_path(site: site)
      within "form" do
        attach_file "item[in_file]", csv_file
        click_on I18n.t("cms.all_contents_moves.read_csv")
      end

      expect(page).to have_css("#cms-all-contents-move-result", wait: 30)

      # only page1 (ok) should be checked, page2 (error) has no checkbox
      expect(page).to have_css("input[name='ids[]']", count: 1)

      accept_confirm do
        within "form" do
          click_on I18n.t("cms.all_contents_moves.execute_move")
        end
      end

      expect(page).to have_css("#cms-all-contents-move-completed", wait: 30)

      page1.reload
      expect(page1.filename).to eq dst1

      page2.reload
      expect(page2.filename).to eq original_page2_filename
    end
  end

  describe "check errors" do
    around do |example|
      perform_enqueued_jobs { example.run }
    end

    context "when destination folder does not exist" do
      let(:csv_data) { build_csv([page1, "nonexistent/page.html"]) }

      it "shows error status" do
        csv_file = create_csv_file(csv_data)

        visit cms_all_contents_moves_path(site: site)
        within "form" do
          attach_file "item[in_file]", csv_file
          click_on I18n.t("cms.all_contents_moves.read_csv")
        end

        expect(page).to have_css("#cms-all-contents-move-result", wait: 30)
        expect(page).to have_css(".status-error")
        expect(page).to have_content(I18n.t('cms.all_contents_moves.errors.not_found_parent_node'))
      end
    end

    context "when page does not exist" do
      let(:csv_data) do
        csv = CSV.generate do |csv|
          csv << [csv_headers[:page_id], csv_headers[:filename]]
          csv << [99_999, "#{node_dst.filename}/nonexistent.html"]
        end
        "\uFEFF" + csv
      end

      it "shows page not found error" do
        csv_file = create_csv_file(csv_data)

        visit cms_all_contents_moves_path(site: site)
        within "form" do
          attach_file "item[in_file]", csv_file
          click_on I18n.t("cms.all_contents_moves.read_csv")
        end

        expect(page).to have_css("#cms-all-contents-move-result", wait: 30)
        expect(page).to have_css(".status-error")
        expect(page).to have_content(I18n.t('cms.all_contents_moves.errors.page_not_found'))
      end
    end

    context "when source and destination are the same" do
      let(:csv_data) { build_csv([page1, page1.filename]) }

      it "shows same filename error" do
        csv_file = create_csv_file(csv_data)

        visit cms_all_contents_moves_path(site: site)
        within "form" do
          attach_file "item[in_file]", csv_file
          click_on I18n.t("cms.all_contents_moves.read_csv")
        end

        expect(page).to have_css("#cms-all-contents-move-result", wait: 30)
        expect(page).to have_css(".status-error")
        expect(page).to have_content(I18n.t('cms.all_contents_moves.errors.same_filename'))
      end
    end

    context "when template CSV is uploaded without changes" do
      let(:csv_data) { build_csv([page1, page1.filename], [page2, page2.filename]) }

      it "shows all rows as same filename error" do
        csv_file = create_csv_file(csv_data)

        visit cms_all_contents_moves_path(site: site)
        within "form" do
          attach_file "item[in_file]", csv_file
          click_on I18n.t("cms.all_contents_moves.read_csv")
        end

        expect(page).to have_css("#cms-all-contents-move-result", wait: 30)
        expect(page).to have_css(".status-error", count: 2)
        expect(page).to have_no_css(".status-ok")
        expect(page).to have_no_css("input[name='ids[]']")
      end
    end

    context "when published page moves to closed folder" do
      let!(:closed_node) { create(:cms_node_page, cur_site: site, state: 'closed') }
      let!(:published_page) do
        create(:article_page, cur_site: site, cur_node: node_src, state: 'public',
          layout_id: layout.id, group_ids: [cms_group.id])
      end
      let(:csv_data) { build_csv([published_page, "#{closed_node.filename}/#{published_page.basename}"]) }

      it "shows destination folder not public error" do
        csv_file = create_csv_file(csv_data)

        visit cms_all_contents_moves_path(site: site)
        within "form" do
          attach_file "item[in_file]", csv_file
          click_on I18n.t("cms.all_contents_moves.read_csv")
        end

        expect(page).to have_css("#cms-all-contents-move-result", wait: 30)
        expect(page).to have_css(".status-error")
        expect(page).to have_content(I18n.t('cms.all_contents_moves.errors.destination_folder_not_public'))
      end
    end

    context "when filename contains invalid characters" do
      let(:csv_data) { build_csv([page1, "#{node_dst.filename}/テスト.html"]) }

      it "shows invalid filename error" do
        csv_file = create_csv_file(csv_data)

        visit cms_all_contents_moves_path(site: site)
        within "form" do
          attach_file "item[in_file]", csv_file
          click_on I18n.t("cms.all_contents_moves.read_csv")
        end

        expect(page).to have_css("#cms-all-contents-move-result", wait: 30)
        expect(page).to have_css(".status-error")
        expect(page).to have_content(I18n.t('cms.all_contents_moves.errors.invalid_filename_chars'))
      end
    end

    context "when CSV has mix of ok and error rows" do
      let(:dst1) { "#{node_dst.filename}/#{page1.basename}" }
      let(:csv_data) { build_csv([page1, dst1], [page2, "nonexistent/page.html"]) }

      it "shows both ok and error statuses" do
        csv_file = create_csv_file(csv_data)

        visit cms_all_contents_moves_path(site: site)
        within "form" do
          attach_file "item[in_file]", csv_file
          click_on I18n.t("cms.all_contents_moves.read_csv")
        end

        expect(page).to have_css("#cms-all-contents-move-result", wait: 30)
        expect(page).to have_css(".status-ok", count: 1)
        expect(page).to have_css(".status-error", count: 1)
        # only ok row should have checkbox
        expect(page).to have_css("input[name='ids[]']", count: 1)
      end
    end

    context "when no file is selected" do
      it "shows invalid csv error" do
        visit cms_all_contents_moves_path(site: site)
        within "form" do
          click_on I18n.t("cms.all_contents_moves.read_csv")
        end

        expect(page).to have_css("#errorExplanation", text: I18n.t("errors.messages.invalid_csv"))
      end
    end
  end

  describe "confirmation status" do
    let(:dst1) { "#{node_dst.filename}/#{page1.basename}" }
    let(:csv_data) { build_csv([page1, dst1]) }

    around do |example|
      perform_enqueued_jobs { example.run }
    end

    context "with single referencing page" do
      let!(:referencing_page) do
        create(:article_page, cur_site: site, cur_node: node_src,
          html: "<a href=\"#{page1.url}\">link</a>", group_ids: [cms_group.id])
      end

      it "shows confirmation status with count and referencing content details" do
        csv_file = create_csv_file(csv_data)

        visit cms_all_contents_moves_path(site: site)
        within "form" do
          attach_file "item[in_file]", csv_file
          click_on I18n.t("cms.all_contents_moves.read_csv")
        end

        expect(page).to have_css("#cms-all-contents-move-result", wait: 30)
        expect(page).to have_css(".status-confirmation")
        expect(page).to have_content("1件")
        expect(page).to have_content("ページ")
        expect(page).to have_content(referencing_page.name)
        expect(page).to have_content(referencing_page.filename)
      end
    end

    context "with multiple referencing contents" do
      let!(:referencing_page1) do
        create(:article_page, cur_site: site, cur_node: node_src,
          html: "<a href=\"#{page1.url}\">link1</a>", group_ids: [cms_group.id])
      end
      let!(:referencing_page2) do
        create(:article_page, cur_site: site, cur_node: node_src,
          html: "<a href=\"#{page1.url}\">link2</a>", group_ids: [cms_group.id])
      end
      let!(:referencing_layout) do
        create(:cms_layout, cur_site: site, html: "<a href=\"#{page1.url}\">link</a>")
      end

      it "shows confirmation with count and all referencing content details" do
        csv_file = create_csv_file(csv_data)

        visit cms_all_contents_moves_path(site: site)
        within "form" do
          attach_file "item[in_file]", csv_file
          click_on I18n.t("cms.all_contents_moves.read_csv")
        end

        expect(page).to have_css("#cms-all-contents-move-result", wait: 30)
        expect(page).to have_css(".status-confirmation")
        expect(page).to have_content("3件")
        expect(page).to have_content(referencing_page1.name)
        expect(page).to have_content(referencing_page2.name)
        expect(page).to have_content("レイアウト")
        expect(page).to have_content(referencing_layout.name)
      end
    end
  end

  describe "move with attribute changes" do
    let(:dst1) { "#{node_dst.filename}/#{page1.basename}" }
    let!(:layout2) { create(:cms_layout, cur_site: site) }
    let!(:cate1) { create(:category_node_node, cur_site: site) }
    let!(:cate2) { create(:category_node_node, cur_site: site) }
    let!(:group2) { Cms::Group.create!(name: "#{cms_group.name}/#{unique_id}") }

    let(:new_name) { "new-title-#{unique_id}" }
    let(:new_index_name) { "new-index-#{unique_id}" }
    let(:new_order) { 10 }
    let(:new_keywords) { "keyword1, keyword2" }
    let(:new_description) { "new-description-#{unique_id}" }
    let(:new_summary) { "<p>new-summary</p>" }
    let(:new_contact_tel) { "03-1234-5678" }
    let(:new_contact_email) { "test@example.jp" }

    around do |example|
      save_config = SS.config.replace_value_at(:cms, 'replace_urls_after_move', false)
      perform_enqueued_jobs { example.run }
      SS.config.replace_value_at(:cms, 'replace_urls_after_move', save_config)
    end

    def execute_move(csv_file)
      visit cms_all_contents_moves_path(site: site)
      within "form" do
        attach_file "item[in_file]", csv_file
        click_on I18n.t("cms.all_contents_moves.read_csv")
      end

      expect(page).to have_css("#cms-all-contents-move-result", wait: 30)

      accept_confirm do
        within "form" do
          click_on I18n.t("cms.all_contents_moves.execute_move")
        end
      end

      expect(page).to have_css("#cms-all-contents-move-completed", wait: 30)
    end

    context "basic info changes" do
      let(:csv_data) do
        csv = CSV.generate do |csv|
          csv << [csv_headers[:page_id], csv_headers[:filename], csv_headers[:name],
                  csv_headers[:index_name], csv_headers[:layout], csv_headers[:order]]
          csv << [page1.id, dst1, new_name, new_index_name, layout2.filename, new_order]
        end
        "\uFEFF" + csv
      end

      it "changes title, index name, layout, and order" do
        execute_move(create_csv_file(csv_data))

        page1.reload
        expect(page1.filename).to eq dst1
        expect(page1.name).to eq new_name
        expect(page1.index_name).to eq new_index_name
        expect(page1.layout_id).to eq layout2.id
        expect(page1.order).to eq new_order
      end
    end

    context "meta info changes" do
      let(:csv_data) do
        csv = CSV.generate do |csv|
          csv << [csv_headers[:page_id], csv_headers[:filename],
                  csv_headers[:keywords], csv_headers[:description], csv_headers[:summary_html]]
          csv << [page1.id, dst1, new_keywords, new_description, new_summary]
        end
        "\uFEFF" + csv
      end

      it "changes keywords, description, and summary" do
        execute_move(create_csv_file(csv_data))

        page1.reload
        expect(page1.filename).to eq dst1
        expect(page1.keywords).to eq %w[keyword1 keyword2]
        expect(page1.description).to eq new_description
        expect(page1.summary_html).to eq new_summary
      end
    end

    context "category changes" do
      let(:csv_data) do
        csv = CSV.generate do |csv|
          csv << [csv_headers[:page_id], csv_headers[:filename], csv_headers[:category]]
          csv << [page1.id, dst1, "#{cate1.filename}\n#{cate2.filename}"]
        end
        "\uFEFF" + csv
      end

      it "changes categories" do
        execute_move(create_csv_file(csv_data))

        page1.reload
        expect(page1.filename).to eq dst1
        expect(page1.category_ids).to match_array [cate1.id, cate2.id]
      end
    end

    context "contact info changes" do
      let(:csv_data) do
        csv = CSV.generate do |csv|
          csv << [csv_headers[:page_id], csv_headers[:filename],
                  csv_headers[:contact_tel], csv_headers[:contact_email],
                  csv_headers[:contact_group_name], csv_headers[:contact_charge]]
          csv << [page1.id, dst1, new_contact_tel, new_contact_email, "新しい課", "担当者A"]
        end
        "\uFEFF" + csv
      end

      it "changes contact information" do
        execute_move(create_csv_file(csv_data))

        page1.reload
        expect(page1.filename).to eq dst1
        expect(page1.contact_tel).to eq new_contact_tel
        expect(page1.contact_email).to eq new_contact_email
        expect(page1.contact_group_name).to eq "新しい課"
        expect(page1.contact_charge).to eq "担当者A"
      end
    end

    context "group changes" do
      let(:csv_data) do
        csv = CSV.generate do |csv|
          csv << [csv_headers[:page_id], csv_headers[:filename], csv_headers[:group_ids]]
          csv << [page1.id, dst1, "#{cms_group.name}\n#{group2.name}"]
        end
        "\uFEFF" + csv
      end

      it "changes management groups" do
        execute_move(create_csv_file(csv_data))

        page1.reload
        expect(page1.filename).to eq dst1
        expect(page1.group_ids).to match_array [cms_group.id, group2.id]
      end
    end
  end

  describe "reset" do
    let(:dst1) { "#{node_dst.filename}/#{page1.basename}" }
    let(:csv_data) { build_csv([page1, dst1]) }

    around do |example|
      save_config = SS.config.replace_value_at(:cms, 'replace_urls_after_move', false)
      perform_enqueued_jobs { example.run }
      SS.config.replace_value_at(:cms, 'replace_urls_after_move', save_config)
    end

    it "returns to initial state after reset" do
      csv_file = create_csv_file(csv_data)

      visit cms_all_contents_moves_path(site: site)
      within "form" do
        attach_file "item[in_file]", csv_file
        click_on I18n.t("cms.all_contents_moves.read_csv")
      end

      expect(page).to have_css("#cms-all-contents-move-result", wait: 30)

      accept_confirm do
        within "form" do
          click_on I18n.t("cms.all_contents_moves.execute_move")
        end
      end

      expect(page).to have_css("#cms-all-contents-move-completed", wait: 30)

      # Click finish
      accept_confirm do
        click_on I18n.t("cms.all_contents_moves.finish")
      end

      # Should return to initial state with history
      expect(page).to have_css("#cms-all-contents-move-settings")
      expect(page).to have_css("input[type='file']")
    end
  end

  describe "branch page follows master page" do
    let!(:branch_page) do
      branch = page1.new_clone
      branch.master = page1
      branch.save!
      branch
    end
    let(:dst1) { "#{node_dst.filename}/#{page1.basename}" }
    let(:csv_data) { build_csv([page1, dst1]) }

    around do |example|
      save_config = SS.config.replace_value_at(:cms, 'replace_urls_after_move', false)
      perform_enqueued_jobs { example.run }
      SS.config.replace_value_at(:cms, 'replace_urls_after_move', save_config)
    end

    it "moves branch page along with master page" do
      branch_basename = branch_page.basename
      csv_file = create_csv_file(csv_data)

      visit cms_all_contents_moves_path(site: site)
      within "form" do
        attach_file "item[in_file]", csv_file
        click_on I18n.t("cms.all_contents_moves.read_csv")
      end

      expect(page).to have_css("#cms-all-contents-move-result", wait: 30)
      expect(page).to have_css(".status-ok")

      accept_confirm do
        within "form" do
          click_on I18n.t("cms.all_contents_moves.execute_move")
        end
      end

      expect(page).to have_css("#cms-all-contents-move-completed", wait: 30)

      # master page moved
      page1.reload
      expect(page1.filename).to eq dst1

      # branch page followed master
      branch_page.reload
      expect(branch_page.filename).to eq "#{node_dst.filename}/#{branch_basename}"
    end

    it "excludes branch page from template CSV" do
      exporter = Cms::AllContentsMoveExporter.new(site: site)
      csv_source = exporter.enum_csv(encoding: "UTF-8").to_a.join.force_encoding("UTF-8")
      csv_source = csv_source[1..-1]
      SS::Csv.open(StringIO.new(csv_source)) do |csv|
        table = csv.read
        ids = table.map { |row| row[csv_headers[:page_id]].to_i }
        expect(ids).to include(page1.id)
        expect(ids).not_to include(branch_page.id)
      end
    end
  end

  describe "permission check" do
    let!(:limited_role) do
      create(:cms_role, cur_site: site, name: "limited-#{unique_id}",
        permissions: %w(use_cms_all_contents read_private_cms_pages))
    end
    let!(:limited_user) do
      create(:cms_user, name: unique_id, email: "#{unique_id}@example.jp",
        group_ids: [cms_group.id], cms_role_ids: [limited_role.id])
    end
    let(:dst1) { "#{node_dst.filename}/#{page1.basename}" }
    let(:csv_data) { build_csv([page1, dst1]) }

    around do |example|
      perform_enqueued_jobs { example.run }
    end

    it "shows permission error for user without move permission" do
      csv_file = create_csv_file(csv_data)

      login_user limited_user
      visit cms_all_contents_moves_path(site: site)
      within "form" do
        attach_file "item[in_file]", csv_file
        click_on I18n.t("cms.all_contents_moves.read_csv")
      end

      expect(page).to have_css("#cms-all-contents-move-result", wait: 30)
      expect(page).to have_css(".status-error")
      expect(page).to have_content(I18n.t('cms.all_contents_moves.errors.not_have_move_permission'))
    end
  end
end
