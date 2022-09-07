require 'spec_helper'

describe "gws_chorg", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:revision) { create(:gws_revision, site_id: site.id) }

  before { login_gws_user }

  context "execute main run without params" do
    it do
      visit gws_chorg_main_path(site: site)
      click_on revision.name
      click_on I18n.t("chorg.menus.revisions.production_execute")

      expectation = expect do
        within "form#item-form" do
          click_on I18n.t("chorg.views.run/confirmation.main.run_button")
        end
      end
      expectation.to have_enqueued_job(Gws::Chorg::MainRunner)
      expect(page).to have_css("#notice", text: I18n.t('chorg.messages.job_started'))
    end
  end

  context "execute main run with reservation" do
    let(:reservation_at) { Time.zone.now.beginning_of_minute + 7.days }

    before do
      @save_config = SS.config.job.default.dup

      config = @save_config.dup
      config["mode"] = "service"
      SS.config.replace_value_at(:job, :default, config)
    end

    after do
      SS.config.replace_value_at(:job, :default, @save_config)
    end

    it do
      visit gws_chorg_main_path(site: site)
      click_on revision.name
      click_on I18n.t("chorg.menus.revisions.production_execute")

      expectation = expect do
        within "form#item-form" do
          fill_in "item[reservation]", with: I18n.l(reservation_at, format: :picker, locale: I18n.default_locale) + "\n"
          click_on I18n.t("chorg.views.run/confirmation.main.run_button")
        end
      end
      expectation.to have_enqueued_job(Gws::Chorg::MainRunner)
      expect(page).to have_css("#notice", text: I18n.t('chorg.messages.job_reserved'))
    end
  end

  context "execute main run with staff_record params" do
    let(:reservation_at) { Time.zone.now.beginning_of_minute + 7.days }

    it do
      visit gws_chorg_main_path(site: site)
      click_on revision.name
      click_on I18n.t("chorg.menus.revisions.production_execute")

      expectation = expect do
        within "form#item-form" do
          select I18n.t("gws/chorg.options.staff_record_state.create"), from: "item[staff_record_state]"
          fill_in "item[staff_record_name]", with: unique_id
          fill_in "item[staff_record_code]", with: rand(2_030..2_040).to_s
          click_on I18n.t("chorg.views.run/confirmation.main.run_button")
        end
      end
      expectation.to have_enqueued_job(Gws::Chorg::MainRunner)
      expect(page).to have_css("#notice", text: I18n.t('chorg.messages.job_started'))
    end
  end

  context "main run result" do
    let!(:task) do
      Gws::Chorg::Task.site(site).and_revision(revision).where(name: "gws:chorg:main_task").first_or_create
    end
    let!(:group0) { create(:gws_group, name: "#{site.name}/#{unique_id}") }
    let!(:group1) { create(:gws_group, name: "#{site.name}/#{unique_id}") }
    let!(:group2) { create(:gws_group, name: "#{site.name}/#{unique_id}") }
    let!(:group3) { create(:gws_group, name: "#{site.name}/#{unique_id}") }
    let!(:group4) { create(:gws_group, name: "#{site.name}/#{unique_id}") }
    let!(:group5) { create(:gws_group, name: "#{site.name}/#{unique_id}") }
    let!(:group6) { create(:gws_group, name: "#{site.name}/#{unique_id}") }
    let!(:changeset0) { create(:gws_add_changeset, revision_id: revision.id) }
    let!(:changeset1) { create(:gws_move_changeset, revision_id: revision.id, source: group0) }
    let!(:changeset2) { create(:gws_unify_changeset, revision_id: revision.id, sources: [group1, group2]) }
    let!(:changeset3) do
      create(:gws_division_changeset, revision_id: revision.id, source: group3, destinations: [group4, group5])
    end
    let!(:changeset4) { create(:gws_delete_changeset, revision_id: revision.id, source: group6) }

    before do
      expect do
        Gws::Chorg::MainRunner.bind(site_id: site.id, user_id: gws_user.id, task_id: task.id).perform_now(revision.name, {})
      end.to output(include("[新設] 成功: 1, 失敗: 0\n")).to_stdout
    end

    it do
      visit gws_chorg_main_path(site: site)
      click_on revision.name
      click_on I18n.t("chorg.menus.revisions.production_execute")
      click_on "結果"
      expect(page).to have_content("[新設] 成功: 1, 失敗: 0")
    end
  end
end
