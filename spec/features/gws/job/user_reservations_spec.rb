require 'spec_helper'

describe "gws_job_user_reservations", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user1) { create :gws_user, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
  let(:user2) { create :gws_user, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
  let(:now) { Time.zone.now.beginning_of_minute }
  let!(:task1) do
    job = Gws::Schedule::TrashPurgeJob.new.bind("site_id" => site.id, "user_id" => user1.id)
    Job::Task.create(
      name: job.job_id, class_name: job.class.name, app_type: job.class.ss_app_type,
      pool: job.queue_name, args: job.arguments, active_job: job.serialize,
      at: now + 8.days, group_id: site.id, user_id: user1.id
    )
  end
  let!(:task2) do
    job = Gws::Notice::NotificationJob.new.bind("site_id" => site.id, "user_id" => user1.id)
    Job::Task.create(
      name: job.job_id, class_name: job.class.name, app_type: job.class.ss_app_type,
      pool: job.queue_name, args: job.arguments, active_job: job.serialize,
      at: now + 3.days, group_id: site.id, user_id: user1.id
    )
  end
  let!(:task3) do
    job = Gws::Reminder::NotificationJob.new.bind("site_id" => site.id, "user_id" => user2.id)
    Job::Task.create(
      name: job.job_id, class_name: job.class.name, app_type: job.class.ss_app_type,
      pool: job.queue_name, args: job.arguments, active_job: job.serialize,
      at: now + 3.days, group_id: job.site_id, user_id: job.user_id
    )
  end
  let!(:tasks) { [ task1, task2, task3 ] }

  context "basic index" do
    context "with user1" do
      it do
        login_user user1

        visit gws_job_user_reservations_path(site: site)
        expect(page).to have_css(".list-item .title", text: I18n.t(task1.class_name.underscore, scope: "job.models"))
        expect(page).to have_css(".list-item .title", text: I18n.t(task2.class_name.underscore, scope: "job.models"))
        expect(page).to have_no_content(I18n.t(task3.class_name.underscore, scope: "job.models"))

        click_on I18n.t(task1.class_name.underscore, scope: "job.models")
        expect(page).to have_content(task1.state)
        expect(page).to have_content(Time.zone.at(task1.at).strftime("%Y/%m/%d %H:%M"))

        visit gws_job_user_reservations_path(site: site)
        click_on I18n.t(task2.class_name.underscore, scope: "job.models")
        expect(page).to have_content(task2.state)
        expect(page).to have_content(Time.zone.at(task2.at).strftime("%Y/%m/%d %H:%M"))

        visit gws_job_user_reservations_path(site: site)
        click_on I18n.t(task1.class_name.underscore, scope: "job.models")
        click_on I18n.t("ss.links.delete")
        within "form" do
          click_on I18n.t("ss.buttons.delete")
        end
        wait_for_notice I18n.t("ss.notice.deleted")

        expect { task1.reload }.to raise_error Mongoid::Errors::DocumentNotFound
      end
    end

    context "with user2" do
      it do
        login_user user2

        visit gws_job_user_reservations_path(site: site)
        expect(page).to have_no_content(I18n.t(task1.class_name.underscore, scope: "job.models"))
        expect(page).to have_no_content(I18n.t(task2.class_name.underscore, scope: "job.models"))
        expect(page).to have_css(".list-item .title", text: I18n.t(task3.class_name.underscore, scope: "job.models"))

        click_on I18n.t(task3.class_name.underscore, scope: "job.models")
        expect(page).to have_content(task3.state)
        expect(page).to have_content(Time.zone.at(task3.at).strftime("%Y/%m/%d %H:%M"))
      end
    end
  end

  describe "destroy all" do
    it do
      login_user user1

      visit gws_job_user_reservations_path(site: site)
      within first(".list-item") do
        first("[name='ids[]']").click
      end
      within ".list-head-action" do
        page.accept_confirm I18n.t("ss.confirm.delete") do
          click_on I18n.t("ss.links.delete")
        end
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect { task1.reload }.not_to raise_error
      expect { task2.reload }.to raise_error Mongoid::Errors::DocumentNotFound
      expect { task3.reload }.not_to raise_error
    end
  end
end
