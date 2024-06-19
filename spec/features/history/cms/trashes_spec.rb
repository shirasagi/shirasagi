require 'spec_helper'

describe "history_cms_trashes", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create_once :article_node_page, filename: "docs", name: "article" }
  let(:file) { create :cms_file, site: site }
  let(:page_item) { create(:article_page, cur_node: node, file_ids: [file.id]) }
  let(:index_path) { history_cms_trashes_path(site: site.id) }
  let(:node_path) { article_pages_path(site: site.id, cid: node.id) }
  let(:page_path) { article_page_path(site: site.id, cid: node.id, id: page_item.id) }
  let(:new_filename) { "#{unique_id}.html" }

  context "with auth" do
    before { login_cms_user }

    it "#destroy" do
      visit page_path
      click_link I18n.t('ss.links.delete')
      click_button I18n.t('ss.buttons.delete')
      wait_for_notice I18n.t('ss.notice.deleted')
      expect(page).to have_no_css('a.title', text: page_item.name)

      expect { page_item.reload }.to raise_error Mongoid::Errors::DocumentNotFound
      expect(History::Trash.all.count).to eq 2
      trashes = History::Trash.all.to_a
      expect(trashes[0].ref_coll).to eq "cms_pages"
      expect(trashes[0].ref_class).to eq "Article::Page"
      expect(trashes[1].ref_coll).to eq "ss_files"
      expect(trashes[1].ref_class).to eq "SS::File"

      visit index_path
      expect(page).to have_css('a.title', text: page_item.name)
      expect(page).to have_css('a.title', text: file.name)

      click_link page_item.name
      expect(page).to have_css('dd', text: page_item.name)

      click_link I18n.t('ss.links.delete')
      click_button I18n.t('ss.buttons.delete')
      wait_for_notice I18n.t('ss.notice.deleted')
      expect(current_path).to eq index_path
      expect(page).to have_no_css('a.title', text: page_item.name)

      visit node_path
      expect(page).to have_no_css('a.title', text: page_item.name)

      expect(History::Trash.all.count).to eq 1
      trashes = History::Trash.all.to_a
      expect(trashes[0].ref_coll).to eq "ss_files"
      expect(trashes[0].ref_class).to eq "SS::File"

      Timecop.freeze(Time.zone.now + History::Trash::TrashPurgeJob::DEFAULT_THRESHOLD_YEARS.years + 1.second) do
        History::Trash::TrashPurgeJob.bind(site_id: site.id).perform_now
        expect(History::Trash.all.count).to eq 0
      end
    end

    it "#destroy_all" do
      visit page_path
      click_link I18n.t('ss.links.delete')
      click_button I18n.t('ss.buttons.delete')
      wait_for_notice I18n.t('ss.notice.deleted')
      expect(page).to have_no_css('a.title', text: page_item.name)

      expect { page_item.reload }.to raise_error Mongoid::Errors::DocumentNotFound
      expect(History::Trash.all.count).to eq 2
      trashes = History::Trash.all.to_a
      expect(trashes[0].ref_coll).to eq "cms_pages"
      expect(trashes[0].ref_class).to eq "Article::Page"
      expect(trashes[1].ref_coll).to eq "ss_files"
      expect(trashes[1].ref_class).to eq "SS::File"

      visit index_path
      expect(page).to have_css('a.title', text: page_item.name)
      expect(page).to have_css('a.title', text: file.name)

      within '.list-head' do
        check(nil)
        click_button I18n.t('ss.links.delete')
      end

      expect(page).to have_content I18n.t('ss.confirm.target_to_delete')
      click_button I18n.t('ss.buttons.delete')

      expect(current_path).to eq index_path
      expect(page).to have_no_css('a.title', text: page_item.name)
      expect(page).to have_no_css('a.title', text: file.name)

      visit node_path
      expect(page).to have_no_css('a.title', text: page_item.name)
      expect(page).to have_no_css('a.title', text: file.name)

      expect(History::Trash.all.count).to eq 0
    end

    it "#undo_delete" do
      visit page_path
      expect(page).to have_css('div.file-view', text: file.name)

      click_link I18n.t('ss.links.delete')
      click_button I18n.t('ss.buttons.delete')
      wait_for_notice I18n.t('ss.notice.deleted')
      expect(page).to have_no_css('a.title', text: page_item.name)

      expect { page_item.reload }.to raise_error Mongoid::Errors::DocumentNotFound
      expect(History::Trash.all.count).to eq 2
      trashes = History::Trash.all.to_a
      expect(trashes[0].ref_coll).to eq "cms_pages"
      expect(trashes[0].ref_class).to eq "Article::Page"
      expect(trashes[1].ref_coll).to eq "ss_files"
      expect(trashes[1].ref_class).to eq "SS::File"

      visit index_path
      expect(page).to have_css('a.title', text: page_item.name)
      expect(page).to have_css('a.title', text: file.name)

      click_link page_item.name
      expect(page).to have_css('dd', text: page_item.name)

      click_link I18n.t('ss.buttons.restore')
      click_button I18n.t('ss.buttons.restore')
      wait_for_notice I18n.t('ss.notice.restored')
      expect(current_path).to eq index_path
      expect(page).to have_no_css('a.title', text: page_item.name)

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
        expect(log.class_name).to eq "History::Trash::RestoreJob"
        expect(log.args.first).to eq trashes[0].id.to_s
      end

      expect(SS::Task.count).to eq 1
      SS::Task.first.tap do |task|
        expect(task.name).to eq "cms_pages:#{page_item.id}"
        expect(task.state).to eq "completed"
      end

      expect { page_item.reload }.not_to raise_error
      expect(page_item.files.count).to eq 1
      expect(page_item.files.first).to be_present
      expect(page_item.files.first.thumb).to be_present

      visit node_path
      expect(page).to have_css('a.title', text: page_item.name)

      visit page_path
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      expect(page).to have_css('div.file-view', text: file.name)

      expect(History::Trash.all.count).to eq 0
    end

    it "#restore_ss_files" do
      visit page_path
      expect(page).to have_css('div.file-view', text: file.name)

      click_link I18n.t('ss.links.delete')
      click_button I18n.t('ss.buttons.delete')
      wait_for_notice I18n.t('ss.notice.deleted')
      expect(page).to have_no_css('a.title', text: page_item.name)

      expect { page_item.reload }.to raise_error Mongoid::Errors::DocumentNotFound
      expect(History::Trash.all.count).to eq 2
      trashes = History::Trash.all.to_a
      expect(trashes[0].ref_coll).to eq "cms_pages"
      expect(trashes[0].ref_class).to eq "Article::Page"
      expect(trashes[1].ref_coll).to eq "ss_files"
      expect(trashes[1].ref_class).to eq "SS::File"

      visit index_path
      expect(page).to have_css('a.title', text: page_item.name)

      click_link file.name
      expect(page).to have_css('dd', text: file.name)

      click_link I18n.t('ss.buttons.restore')
      click_button I18n.t('ss.buttons.restore')
      wait_for_notice I18n.t('ss.notice.restored')
      expect(current_path).to eq index_path
      expect(page).to have_no_css('a.title', text: file.name)

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
        expect(log.class_name).to eq "History::Trash::RestoreJob"
        expect(log.args.first).to eq trashes[1].id.to_s
      end

      expect(SS::Task.count).to eq 1
      SS::Task.first.tap do |task|
        expect(task.name).to eq "ss_files:#{file.id}"
        expect(task.state).to eq "completed"
      end

      expect { file.reload }.to raise_error Mongoid::Errors::DocumentNotFound

      expect(Cms::File.all.count).to eq 1
      expect(History::Trash.all.count).to eq 1
    end

    # hide undo delete all from head because I thought this is dangerous for node, page which parent is deleted
    # or some other specific conditions met.
    #
    # it "#undo_delete_all" do
    #   visit page_path
    #   expect(page).to have_css('div.file-view', text: file.name)
    #
    #   click_link I18n.t('ss.links.delete')
    #   click_button I18n.t('ss.buttons.delete')
    #   expect(page).to have_no_css('a.title', text: page_item.name)
    #
    #   expect { page_item.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    #   expect(History::Trash.all.count).to eq 2
    #   trashes = History::Trash.all.to_a
    #   expect(trashes[0].ref_coll).to eq "cms_pages"
    #   expect(trashes[0].ref_class).to eq "Article::Page"
    #   expect(trashes[1].ref_coll).to eq "ss_files"
    #   expect(trashes[1].ref_class).to eq "SS::File"
    #
    #   visit index_path
    #   expect(page).to have_css('a.title', text: page_item.name)
    #
    #   within '.list-head' do
    #     check(nil)
    #     page.accept_confirm do
    #       click_button I18n.t('ss.buttons.restore')
    #     end
    #   end
    #   expect(current_path).to eq index_path
    #   expect(page).to have_no_css('a.title', text: page_item.name)
    #
    #   expect { page_item.reload }.not_to raise_error
    #   expect(page_item.files.count).to eq 1
    #   expect(page_item.files.first).to be_present
    #   expect(page_item.files.first.thumb).to be_present
    #
    #   visit node_path
    #   expect(page).to have_css('a.title', text: page_item.name)
    #
    #   visit page_path
    #   expect(page).to have_css('div.file-view', text: file.name)
    #
    #   expect(History::Trash.all.count).to eq 0
    # end

    it "#undo_delete as another filename" do
      visit page_path
      wait_for_turbo_frame "#workflow-branch-frame"
      expect(page).to have_css('div.file-view', text: file.name)

      click_link I18n.t('ss.links.delete')
      click_button I18n.t('ss.buttons.delete')
      wait_for_notice I18n.t('ss.notice.deleted')
      expect(page).to have_no_css('a.title', text: page_item.name)

      expect { page_item.reload }.to raise_error Mongoid::Errors::DocumentNotFound
      expect(History::Trash.all.count).to eq 2
      trashes = History::Trash.all.to_a
      expect(trashes[0].ref_coll).to eq "cms_pages"
      expect(trashes[0].ref_class).to eq "Article::Page"
      expect(trashes[1].ref_coll).to eq "ss_files"
      expect(trashes[1].ref_class).to eq "SS::File"

      visit index_path
      expect(page).to have_css('a.title', text: page_item.name)

      click_link page_item.name
      expect(page).to have_css('dd', text: page_item.name)

      click_link I18n.t('ss.buttons.restore')

      wait_for_event_fired("change") { click_on I18n.t("ss.links.change") }
      fill_in "item[basename]", with: new_filename

      click_button I18n.t('ss.buttons.restore')
      wait_for_notice I18n.t('ss.notice.restored')
      expect(current_path).to eq index_path
      expect(page).to have_no_css('a.title', text: page_item.name)

      expect { page_item.reload }.not_to raise_error
      expect(page_item.files.count).to eq 1
      expect(page_item.files.first).to be_present
      expect(page_item.files.first.thumb).to be_present
      expect(page_item.filename).to end_with "/" + new_filename

      visit node_path
      expect(page).to have_css('a.title', text: page_item.name)

      visit page_path
      wait_for_turbo_frame "#workflow-branch-frame"
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      expect(page).to have_css('div.file-view', text: file.name)

      expect(History::Trash.all.count).to eq 0
    end
  end

  context "when branch page is restored" do
    before { login_cms_user }

    it do
      visit page_path
      expect(page).to have_css('div.file-view', text: file.name)

      # create branch page
      within "#addon-workflow-agents-addons-branch" do
        wait_for_turbo_frame "#workflow-branch-frame"
        wait_event_to_fire "turbo:frame-load" do
          click_on I18n.t("workflow.create_branch")
        end
        expect(page).to have_css('.see.branch', text: I18n.t("workflow.notice.created_branch_page"))
        within ".result .branches" do
          expect(page).to have_css(".name", text: page_item.name)
        end
      end

      page_item.reload
      expect(page_item.branches.count).to eq 1
      branch_page = page_item.branches.first
      expect(branch_page.master_id).to eq page_item.id
      expect(History::Trash.all.count).to eq 0

      # delete branch page
      within "#addon-workflow-agents-addons-branch" do
        wait_for_turbo_frame "#workflow-branch-frame"
        within ".branch" do
          click_on page_item.name
        end
      end
      wait_for_turbo_frame "#workflow-branch-frame"
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      click_on I18n.t('ss.links.delete')
      within "form" do
        click_on I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      page_item.reload
      expect(page_item.branches.count).to eq 0
      expect { branch_page.reload }.to raise_error Mongoid::Errors::DocumentNotFound
      # 差し替えページの場合、添付ファイルは差し替え元のファイルと共有しているため、
      # 差し替えページを削除すると History::Trash は差し替えページの分のみが増える。
      expect(History::Trash.all.count).to eq 1

      visit index_path
      expect(page).to have_css('a.title', text: page_item.name)

      click_link page_item.name
      click_on I18n.t('ss.buttons.restore')
      within "form" do
        click_on I18n.t('ss.buttons.restore')
      end
      wait_for_notice I18n.t('ss.notice.restored')

      page_item.reload
      expect(page_item.branches.count).to eq 0
      expect(page_item.files.count).to eq 1
      expect(page_item.files.first.id).to eq file.id
      file.reload
      expect(file.owner_item_type).to eq page_item.class.name
      expect(file.owner_item_id).to eq page_item.id

      # 差し替えページをゴミ箱から復元すると、差し替え元との関係が失われ、複製したようになる。
      branch_page.reload
      expect(branch_page.master_id).to be_blank
      # そして、添付ファイルは複製され、差し替え元との関係が失われる
      expect(branch_page.files.count).to eq 1
      branch_page.files.first.tap do |branch_file|
        expect(branch_file.id).not_to eq file.id
        expect(branch_file.owner_item_type).to eq branch_page.class.name
        expect(branch_file.owner_item_id).to eq branch_page.id
      end

      expect(History::Trash.all.count).to eq 0

      visit page_path
      within "#addon-workflow-agents-addons-branch" do
        wait_for_turbo_frame "#workflow-branch-frame"
        within ".branch" do
          expect(page).to have_button(I18n.t("workflow.create_branch"))
          expect(page).to have_no_content(page_item.name)
        end
      end
    end
  end

  context "duplicated restore protection" do
    before { login_cms_user }

    context "task is already running" do
      let(:task) { SS::Task.create(site_id: site.id, name: "cms_pages:#{page_item.id}") }

      before do
        expect(task.start).to be_truthy
      end

      it do
        # move page to trash
        visit page_path
        click_link I18n.t('ss.links.delete')
        click_button I18n.t('ss.buttons.delete')
        wait_for_notice I18n.t('ss.notice.deleted')

        expect(History::Trash.all.count).to eq 2

        # restore it
        visit index_path
        click_link page_item.name
        click_link I18n.t('ss.buttons.restore')
        click_button I18n.t('ss.buttons.restore')

        expect(page).to have_css(".errorExplanation", text: I18n.t('errors.messages.other_task_is_running'))
      end
    end
  end
end
