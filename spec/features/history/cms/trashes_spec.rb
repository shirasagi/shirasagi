require 'spec_helper'

describe "history_cms_trashes", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create_once :article_node_page, filename: "docs", name: "article" }
  let(:file) { create :cms_file, site: site }
  let(:page_item) { create(:article_page, cur_node: node, file_ids: [file.id]) }
  let(:index_path) { history_cms_trashes_path(site: site.id) }
  let(:node_path) { article_pages_path(site: site.id, cid: node.id) }
  let(:page_path) { article_page_path(site: site.id, cid: node.id, id: page_item.id) }

  context "with auth" do
    before { login_cms_user }

    it "#destroy" do
      visit page_path
      click_link I18n.t('ss.links.delete')
      click_button I18n.t('ss.buttons.delete')
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
      expect(current_path).to eq index_path
      expect(page).to have_no_css('a.title', text: page_item.name)

      visit node_path
      expect(page).to have_no_css('a.title', text: page_item.name)

      expect(History::Trash.all.count).to eq 1
      trashes = History::Trash.all.to_a
      expect(trashes[0].ref_coll).to eq "ss_files"
      expect(trashes[0].ref_class).to eq "SS::File"

      Timecop.freeze(Time.zone.now + History::Trash::TrashPurgeJob::DEFAULT_THRESHOLD_DAYS.days + 1.second) do
        History::Trash::TrashPurgeJob.bind(site_id: site).perform_now
        expect(History::Trash.all.count).to eq 0
      end
    end

    it "#destroy_all" do
      visit page_path
      click_link I18n.t('ss.links.delete')
      click_button I18n.t('ss.buttons.delete')
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
        page.accept_confirm do
          click_button I18n.t('ss.links.delete')
        end
      end
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
      expect(current_path).to eq index_path
      expect(page).to have_no_css('a.title', text: page_item.name)

      expect { page_item.reload }.not_to raise_error
      expect(page_item.files.count).to eq 1
      expect(page_item.files.first).to be_present
      expect(page_item.files.first.thumb).to be_present

      visit node_path
      expect(page).to have_css('a.title', text: page_item.name)

      visit page_path
      expect(page).to have_css('div.file-view', text: file.name)

      expect(History::Trash.all.count).to eq 0
    end

    it "#restore_ss_files" do
      visit page_path
      expect(page).to have_css('div.file-view', text: file.name)

      click_link I18n.t('ss.links.delete')
      click_button I18n.t('ss.buttons.delete')
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
      expect(current_path).to eq index_path
      expect(page).to have_no_css('a.title', text: file.name)

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
  end

  context "when branch page is restored" do
    before { login_cms_user }

    it do
      visit page_path
      expect(page).to have_css('div.file-view', text: file.name)

      # create branch page
      within "#addon-workflow-agents-addons-branch" do
        within ".branch" do
          click_on I18n.t("workflow.create_branch")
          within ".result .branches" do
            expect(page).to have_css(".name", text: page_item.name)
          end
        end
      end

      page_item.reload
      expect(page_item.branches.count).to eq 1
      branch_page = page_item.branches.first
      expect(branch_page.master_id).to eq page_item.id

      # delete branch page
      within "#addon-workflow-agents-addons-branch" do
        within ".branch" do
          click_on page_item.name
        end
      end
      click_on I18n.t('ss.links.delete')
      within "form" do
        click_on I18n.t('ss.buttons.delete')
      end

      page_item.reload
      expect(page_item.branches.count).to eq 0
      expect { branch_page.reload }.to raise_error Mongoid::Errors::DocumentNotFound
      expect(History::Trash.all.count).to eq 2

      visit index_path
      expect(page).to have_css('a.title', text: page_item.name)

      click_link page_item.name
      click_on I18n.t('ss.buttons.restore')
      within "form" do
        click_on I18n.t('ss.buttons.restore')
      end

      page_item.reload
      expect(page_item.branches.count).to eq 0
      branch_page.reload
      expect(branch_page.master_id).to be_blank
      expect(History::Trash.all.count).to eq 0

      visit page_path
      within "#addon-workflow-agents-addons-branch" do
        within ".branch" do
          expect(page).to have_css(".create-branch", text: I18n.t("workflow.create_branch"))
          expect(page).to have_no_content(page_item.name)
        end
      end
    end
  end
end
