require 'spec_helper'

describe "chorg_run", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:revision) { create(:revision, site_id: site.id) }
  let(:changeset) { create(:add_changeset, revision_id: revision.id) }
  let(:revision_show_path) { chorg_revision_path site.id, revision.id }

  around do |example|
    perform_enqueued_jobs do
      example.run
    end
  end

  context "with test run" do
    let(:test_run_path) { chorg_run_confirmation_path site.id, revision.id, "test" }

    it "without login" do
      # ensure that entities has existed.
      expect(changeset).not_to be_nil

      visit test_run_path
      expect(current_path).to eq sns_login_path
    end

    it "without auth" do
      # ensure that entities has existed.
      expect(changeset).not_to be_nil

      login_ss_user
      visit test_run_path
      expect(status_code).to eq 403
    end

    it "runs test" do
      # ensure that entities has existed.
      expect(changeset).not_to be_nil

      login_cms_user
      visit test_run_path
      expect(status_code).to eq 200
      within "form#item-form" do
        click_button I18n.t("chorg.views.run/confirmation.test.run_button")
      end
      expect(status_code).to eq 200
      expect(current_path).to eq revision_show_path
      revision.reload
      expect(revision.job_ids.length).to eq 1

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(include('INFO -- : Started Job'))
        expect(log.logs).to include(include('INFO -- : Completed Job'))
      end

      expect(Chorg::Task.count).to eq 1
      Chorg::Task.first.tap do |task|
        expect(task.state).to eq 'stop'
        expect(task.entity_logs.count).to eq 1
        expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['creates']).to include({ 'name' => changeset.destinations.first["name"] })
      end
    end

    context "with add_newly_created_group_to_site" do
      it "runs test" do
        # ensure that entities has existed.
        expect(changeset).not_to be_nil

        login_cms_user
        visit test_run_path
        expect(status_code).to eq 200
        within "form#item-form" do
          check Chorg::RunParams.t(:add_newly_created_group_to_site)
          click_button I18n.t("chorg.views.run/confirmation.test.run_button")
        end
        expect(status_code).to eq 200
        expect(current_path).to eq revision_show_path
        revision.reload
        expect(revision.job_ids.length).to eq 1

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(include('INFO -- : Started Job'))
          expect(log.logs).to include(include('INFO -- : Completed Job'))
        end

        expect(Chorg::Task.count).to eq 1
        Chorg::Task.first.tap do |task|
          expect(task.state).to eq 'stop'
          expect(task.entity_logs.count).to eq 2
          expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
          expect(task.entity_logs[0]['creates']).to include({ 'name' => changeset.destinations.first["name"] })
          expect(task.entity_logs[1]['model']).to eq 'Cms::Site'
          expect(task.entity_logs[1]['id']).to eq site.id.to_s
          expect(task.entity_logs[1]['changes']).to include('group_ids')
        end
      end
    end
  end

  context "with main run" do
    let(:main_run_path) { chorg_run_confirmation_path site.id, revision.id, "main" }

    it "without login" do
      # ensure that entities has existed.
      expect(changeset).not_to be_nil

      visit main_run_path
      expect(current_path).to eq sns_login_path
    end

    it "without auth" do
      # ensure that entities has existed.
      expect(changeset).not_to be_nil

      login_ss_user
      visit main_run_path
      expect(status_code).to eq 403
    end

    it "runs main" do
      # ensure that entities has existed.
      expect(changeset).not_to be_nil

      login_cms_user
      visit main_run_path
      expect(status_code).to eq 200
      within "form#item-form" do
        click_button I18n.t("chorg.views.run/confirmation.main.run_button")
      end
      expect(status_code).to eq 200
      expect(current_path).to eq revision_show_path
      revision.reload
      expect(revision.job_ids.length).to eq 1

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(include('INFO -- : Started Job'))
        expect(log.logs).to include(include('INFO -- : Completed Job'))
      end

      expect(Chorg::Task.count).to eq 1
      Chorg::Task.first.tap do |task|
        expect(task.state).to eq 'stop'
        expect(task.entity_logs.count).to eq 1
        expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['creates']).to include({ 'name' => changeset.destinations.first["name"] })
      end
    end

    context "with add_newly_created_group_to_site" do
      it "runs main" do
        # ensure that entities has existed.
        expect(changeset).not_to be_nil

        login_cms_user
        visit main_run_path
        expect(status_code).to eq 200
        within "form#item-form" do
          check Chorg::RunParams.t(:add_newly_created_group_to_site)
          click_button I18n.t("chorg.views.run/confirmation.main.run_button")
        end
        expect(status_code).to eq 200
        expect(current_path).to eq revision_show_path
        revision.reload
        expect(revision.job_ids.length).to eq 1

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(include('INFO -- : Started Job'))
          expect(log.logs).to include(include('INFO -- : Completed Job'))
        end

        expect(Chorg::Task.count).to eq 1
        Chorg::Task.first.tap do |task|
          expect(task.state).to eq 'stop'
          expect(task.entity_logs.count).to eq 2
          expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
          expect(task.entity_logs[0]['creates']).to include({ 'name' => changeset.destinations.first["name"] })
          expect(task.entity_logs[1]['model']).to eq 'Cms::Site'
          expect(task.entity_logs[1]['id']).to eq site.id.to_s
          expect(task.entity_logs[1]['changes']).to include('group_ids')
        end
      end
    end
  end
end
