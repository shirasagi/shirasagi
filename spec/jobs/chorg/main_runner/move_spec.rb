require 'spec_helper'

describe Chorg::MainRunner, dbscope: :example do
  let!(:root_group) { create(:revision_root_group) }
  let!(:site) { create(:cms_site, group_ids: [root_group.id]) }
  let!(:task) { Chorg::Task.create!(name: unique_id, site_id: site.id) }
  let(:job_opts) { { 'newly_created_group_to_site' => 'add' } }

  context "with move" do
    let!(:source_group) { create(:revision_new_group) }
    let!(:revision) { create(:revision, site_id: site.id) }
    let!(:source_page) { create(:revision_page, cur_site: site, group: source_group) }
    let!(:changeset) { create(:move_changeset, revision_id: revision.id, source: source_group) }

    context "with all supported attributes" do
      context "contact_group_relation is 'related'" do
        it do
          # execute
          job = described_class.bind(site_id: site.id, task_id: task.id)
          expect { job.perform_now(revision.name, job_opts) }.to output(include("[移動] 成功: 1, 失敗: 0\n")).to_stdout

          # check for job was succeeded
          expect(Job::Log.count).to eq 1
          Job::Log.first.tap do |log|
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
          end

          # check group
          Cms::Group.where(id: source_group.id).first.tap do |group_after_move|
            changeset.destinations.first.tap do |destination|
              expect(group_after_move.name).not_to eq source_group.name
              expect(group_after_move.name).to eq destination["name"]
              expect(group_after_move.order.to_s).to eq destination["order"]
              expect(group_after_move.ldap_dn).to eq destination["ldap_dn"]

              expect(group_after_move.contact_groups).to have(source_group.contact_groups.count).items
              group_after_move.contact_groups[0].tap do |contact_after_move|
                source_contact0 = source_group.contact_groups[0]
                expect(contact_after_move.id).to eq source_contact0.id

                destination_contact = destination["contact_groups"][0]
                expect(contact_after_move.name).to eq destination_contact["name"]
                expect(contact_after_move.main_state).to eq destination_contact["main_state"]
                expect(contact_after_move.contact_group_name).to eq destination_contact["contact_group_name"]
                expect(contact_after_move.contact_tel).to eq destination_contact["contact_tel"]
                expect(contact_after_move.contact_fax).to eq destination_contact["contact_fax"]
                expect(contact_after_move.contact_email).to eq destination_contact["contact_email"]
                expect(contact_after_move.contact_link_url).to eq destination_contact["contact_link_url"]
                expect(contact_after_move.contact_link_name).to eq destination_contact["contact_link_name"]
              end
            end
          end

          # check page
          Cms::Page.find(source_page.id).tap do |page_after_move|
            expect(page_after_move.group_ids).to eq [ source_group.id ]
            expect(page_after_move.filename).to eq source_page.filename
            expect(page_after_move.contact_group_id).to eq source_group.id
            main_source_contact = source_group.contact_groups.where(main_state: "main").first
            expect(page_after_move.contact_group_contact_id).to eq main_source_contact.id
            destination = changeset.destinations.first
            main_destination_contact = destination["contact_groups"].find { |contact| contact["main_state"] == "main" }
            expect(page_after_move.contact_charge).to eq main_destination_contact["contact_group_name"]
            expect(page_after_move.contact_tel).to eq main_destination_contact["contact_tel"]
            expect(page_after_move.contact_fax).to eq main_destination_contact["contact_fax"]
            expect(page_after_move.contact_email).to eq main_destination_contact["contact_email"]
            expect(page_after_move.contact_link_url).to eq main_destination_contact["contact_link_url"]
            expect(page_after_move.contact_link_name).to eq main_destination_contact["contact_link_name"]
          end

          task.reload
          expect(task.state).to eq 'completed'
          expect(task.entity_logs.count).to eq 2
          expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
          expect(task.entity_logs[0]['class']).to eq 'Cms::Group'
          expect(task.entity_logs[0]['id']).to eq source_group.id.to_s
          expect(task.entity_logs[0]['changes']).to include('name')
          expect(task.entity_logs[1]['model']).to eq 'Cms::Page'
          expect(task.entity_logs[1]['class']).to eq 'Article::Page'
          expect(task.entity_logs[1]['id']).to eq '1'
          expect(task.entity_logs[1]['changes']).to include(
            'contact_tel', 'contact_fax', 'contact_email', 'contact_link_url', 'contact_link_name'
          )
        end
      end

      context "contact_group_relation is 'unrelated'" do
        before do
          source_page.update!(contact_group_relation: "unrelated")
        end

        it do
          # execute
          job = described_class.bind(site_id: site.id, task_id: task.id)
          expect { job.perform_now(revision.name, job_opts) }.to output(include("[移動] 成功: 1, 失敗: 0\n")).to_stdout

          # check for job was succeeded
          expect(Job::Log.count).to eq 1
          Job::Log.first.tap do |log|
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
          end

          # check group
          Cms::Group.where(id: source_group.id).first.tap do |group_after_move|
            changeset.destinations.first.tap do |destination|
              expect(group_after_move.name).not_to eq source_group.name
              expect(group_after_move.name).to eq destination["name"]
              expect(group_after_move.order.to_s).to eq destination["order"]
              expect(group_after_move.ldap_dn).to eq destination["ldap_dn"]

              expect(group_after_move.contact_groups).to have(source_group.contact_groups.count).items
              group_after_move.contact_groups[0].tap do |contact_after_move|
                source_contact0 = source_group.contact_groups[0]
                expect(contact_after_move.id).to eq source_contact0.id

                destination_contact = destination["contact_groups"][0]
                expect(contact_after_move.name).to eq destination_contact["name"]
                expect(contact_after_move.main_state).to eq destination_contact["main_state"]
                expect(contact_after_move.contact_group_name).to eq destination_contact["contact_group_name"]
                expect(contact_after_move.contact_tel).to eq destination_contact["contact_tel"]
                expect(contact_after_move.contact_fax).to eq destination_contact["contact_fax"]
                expect(contact_after_move.contact_email).to eq destination_contact["contact_email"]
                expect(contact_after_move.contact_link_url).to eq destination_contact["contact_link_url"]
                expect(contact_after_move.contact_link_name).to eq destination_contact["contact_link_name"]
              end
            end
          end

          # check page
          Cms::Page.find(source_page.id).tap do |page_after_move|
            expect(page_after_move.group_ids).to eq [ source_group.id ]
            expect(page_after_move.filename).to eq source_page.filename
            expect(page_after_move.contact_group_id).to eq source_group.id
            main_source_contact = source_group.contact_groups.where(main_state: "main").first
            expect(page_after_move.contact_group_contact_id).to eq main_source_contact.id
            expect(page_after_move.contact_charge).to eq source_page.contact_charge
            expect(page_after_move.contact_tel).to eq source_page.contact_tel
            expect(page_after_move.contact_fax).to eq source_page.contact_fax
            expect(page_after_move.contact_email).to eq source_page.contact_email
            expect(page_after_move.contact_link_url).to eq source_page.contact_link_url
            expect(page_after_move.contact_link_name).to eq source_page.contact_link_name
          end

          task.reload
          expect(task.state).to eq 'completed'
          expect(task.entity_logs.count).to eq 2
          expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
          expect(task.entity_logs[0]['class']).to eq 'Cms::Group'
          expect(task.entity_logs[0]['id']).to eq source_group.id.to_s
          expect(task.entity_logs[0]['changes']).to include('name')
          expect(task.entity_logs[1]['model']).to eq 'Cms::Page'
          expect(task.entity_logs[1]['class']).to eq 'Article::Page'
          expect(task.entity_logs[1]['id']).to eq source_page.id.to_s
          expect(task.entity_logs[1]['changes']).to be_present
        end
      end
    end

    context "with only move name" do
      let!(:changeset) { create(:move_changeset_only_name, revision_id: revision.id, source: source_group) }

      it do
        # ensure create models
        expect(changeset).not_to be_nil
        expect(source_page).not_to be_nil
        # execute
        job = described_class.bind(site_id: site.id, task_id: task.id)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[移動] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        # check group
        Cms::Group.where(id: source_group.id).first.tap do |group_after_move|
          changeset.destinations.first.tap do |destination|
            expect(group_after_move.name).not_to eq source_group.name
            expect(group_after_move.name).to eq destination["name"]
            # these attributes are expected not to be changed.
            expect(group_after_move.contact_tel).to eq source_group.contact_tel
            expect(group_after_move.contact_fax).to eq source_group.contact_fax
            expect(group_after_move.contact_email).to eq source_group.contact_email
            expect(group_after_move.contact_link_url).to eq source_group.contact_link_url
            expect(group_after_move.contact_link_name).to eq source_group.contact_link_name
            expect(group_after_move.ldap_dn).to eq source_group.ldap_dn
          end
        end

        # check page
        Cms::Page.find(source_page.id).tap do |page_after_move|
          expect(page_after_move.group_ids).to eq [ source_group.id ]
          expect(page_after_move.filename).to eq source_page.filename
          expect(page_after_move.contact_group_id).to eq source_group.id
          main_source_contact = source_group.contact_groups.where(main_state: "main").first
          expect(page_after_move.contact_group_contact_id).to eq main_source_contact.id
          expect(page_after_move.contact_charge).to eq main_source_contact.contact_group_name
          expect(page_after_move.contact_tel).to eq main_source_contact.contact_tel
          expect(page_after_move.contact_fax).to eq main_source_contact.contact_fax
          expect(page_after_move.contact_email).to eq main_source_contact.contact_email
          expect(page_after_move.contact_link_url).to eq main_source_contact.contact_link_url
          expect(page_after_move.contact_link_name).to eq main_source_contact.contact_link_name
        end

        task.reload
        expect(task.state).to eq 'completed'
        expect(task.entity_logs.count).to eq 2
        expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['id']).to eq source_group.id.to_s
        expect(task.entity_logs[0]['changes']).to include("name")
        expect(task.entity_logs[1]['model']).to eq 'Cms::Page'
        expect(task.entity_logs[1]['class']).to eq 'Article::Page'
        expect(task.entity_logs[1]['id']).to eq source_page.id.to_s
        expect(task.entity_logs[1]['changes']).to be_present
      end
    end

    context "with workflow approving Article::Page" do
      let(:user1) do
        create(:cms_user, name: unique_id.to_s, email: "#{unique_id}@example.jp",
               group_ids: [source_group.id], cms_role_ids: [cms_role.id])
      end
      let(:user2) do
        create(:cms_user, name: unique_id.to_s, email: "#{unique_id}@example.jp",
               group_ids: [source_group.id], cms_role_ids: [cms_role.id])
      end
      let!(:source_page) do
        page = build(:revision_page, cur_site: site, group: source_group, workflow_user_id: user1.id,
               workflow_state: "request",
               workflow_comment: "",
               workflow_approvers: [{level: 1, user_id: user2.id, state: "request", comment: ""}],
               workflow_required_counts: [false])
        page.cur_site = site
        page.save!
        page
      end

      it do
        # ensure create models
        expect(changeset).not_to be_nil
        expect(source_page).not_to be_nil
        # execute
        job = described_class.bind(site_id: site.id, task_id: task.id, user_id: user1.id)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[移動] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        # check group
        Cms::Group.where(id: source_group.id).first.tap do |group_after_move|
          expect(group_after_move.name).not_to eq source_group.name
          expect(group_after_move.name).to eq changeset.destinations.first["name"]
        end

        # check page
        Cms::Page.find(source_page.id).tap do |page_after_move|
          expect(page_after_move.group_ids).to eq [ source_group.id ]
          expect(page_after_move.filename).to eq source_page.filename
          expect(page_after_move.contact_group_id).to eq source_group.id
          main_source_contact = source_group.contact_groups.where(main_state: "main").first
          expect(page_after_move.contact_group_contact_id).to eq main_source_contact.id
          destination = changeset.destinations.first
          main_destination_contact = destination["contact_groups"].find { |contact| contact["main_state"] == "main" }
          expect(page_after_move.contact_tel).to eq main_destination_contact["contact_tel"]
          expect(page_after_move.contact_fax).to eq main_destination_contact["contact_fax"]
          expect(page_after_move.contact_email).to eq main_destination_contact["contact_email"]
          expect(page_after_move.contact_link_url).to eq main_destination_contact["contact_link_url"]
          expect(page_after_move.contact_link_name).to eq main_destination_contact["contact_link_name"]
        end

        task.reload
        expect(task.state).to eq 'completed'
        expect(task.entity_logs.count).to eq 2
        expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['class']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['id']).to eq source_group.id.to_s
        expect(task.entity_logs[0]['changes']).to include(
          'name', 'contact_tel', 'contact_fax', 'contact_email', 'contact_link_url', 'contact_link_name'
        )
        expect(task.entity_logs[1]['model']).to eq 'Cms::Page'
        expect(task.entity_logs[1]['class']).to eq 'Article::Page'
        expect(task.entity_logs[1]['id']).to eq '1'
        expect(task.entity_logs[1]['changes']).to include(
          'contact_tel', 'contact_fax', 'contact_email', 'contact_link_url', 'contact_link_name'
        )
      end
    end

    context 'グループの連絡先: 0件 → 1件, ページの連動: 有効' do
      let(:source_group) { create(:cms_group, name: "組織変更/グループ#{unique_id}") }
      let!(:source_page) do
        create(
          :article_page, cur_site: site, contact_group: source_group, contact_charge: source_group.trailing_name,
          contact_tel: unique_tel, contact_fax: unique_tel, contact_email: unique_email,
          contact_link_url: "/#{unique_id}/", contact_link_name: "link_name-#{unique_id}")
      end

      it do
        # ensure create models
        expect(changeset).not_to be_nil
        expect(source_group.contact_groups.count).to eq 0
        expect(source_page.contact_group_id).to eq source_group.id
        expect(source_page.contact_group_contact_id).to be_blank
        # execute
        job = described_class.bind(site_id: site.id, task_id: task.id)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[移動] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        # check group
        Cms::Group.where(id: source_group.id).first.tap do |group_after_move|
          destination = changeset.destinations.first

          expect(group_after_move.name).not_to eq source_group.name
          expect(group_after_move.order.to_s).to eq destination["order"]
          expect(group_after_move.ldap_dn).to eq destination["ldap_dn"]

          expect(group_after_move.contact_groups).not_to have(source_group.contact_groups.count).items
          expect(group_after_move.contact_groups).to have(1).items
          group_after_move.contact_groups[0].tap do |contact_after_move|
            destination_contact = destination["contact_groups"][0]
            expect(contact_after_move.name).to eq destination_contact["name"]
            expect(contact_after_move.main_state).to eq destination_contact["main_state"]
            expect(contact_after_move.contact_group_name).to eq destination_contact["contact_group_name"]
            expect(contact_after_move.contact_tel).to eq destination_contact["contact_tel"]
            expect(contact_after_move.contact_fax).to eq destination_contact["contact_fax"]
            expect(contact_after_move.contact_email).to eq destination_contact["contact_email"]
            expect(contact_after_move.contact_link_url).to eq destination_contact["contact_link_url"]
            expect(contact_after_move.contact_link_name).to eq destination_contact["contact_link_name"]
          end
        end

        # check page
        Cms::Page.find(source_page.id).tap do |page_after_move|
          expect(page_after_move.contact_group_id).to eq source_group.id
          expect(page_after_move.contact_group_contact_id).to be_blank
          expect(page_after_move.contact_charge).to eq source_page.contact_charge
          expect(page_after_move.contact_tel).to eq source_page.contact_tel
          expect(page_after_move.contact_fax).to eq source_page.contact_fax
          expect(page_after_move.contact_email).to eq source_page.contact_email
          expect(page_after_move.contact_link_url).to eq source_page.contact_link_url
          expect(page_after_move.contact_link_name).to eq source_page.contact_link_name
        end

        task.reload
        expect(task.state).to eq 'completed'
        expect(task.entity_logs.count).to eq 2
        expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['class']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['id']).to eq source_group.id.to_s
        expect(task.entity_logs[0]['changes']).to include(
          'name', 'contact_tel', 'contact_fax', 'contact_email', 'contact_link_url', 'contact_link_name'
        )
        expect(task.entity_logs[1]['model']).to eq 'Cms::Page'
        expect(task.entity_logs[1]['class']).to eq 'Article::Page'
        expect(task.entity_logs[1]['id']).to eq '1'
        expect(task.entity_logs[1]['changes']).to be_present
      end
    end

    context 'グループの連絡先: 1件 → 0件, ページの連動: 有効' do
      before do
        destinations = changeset.destinations
        destinations = destinations.dup
        destinations[0].delete("contact_groups")
        changeset.update!(destinations: destinations)
      end

      it do
        # execute
        job = described_class.bind(site_id: site.id, task_id: task.id)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[移動] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        # check group
        Cms::Group.where(id: source_group.id).first.tap do |group_after_move|
          expect(group_after_move.contact_groups).to be_blank
        end

        # check page
        Cms::Page.find(source_page.id).tap do |page_after_move|
          expect(page_after_move.contact_group_id).to eq source_group.id
          expect(page_after_move.contact_group_contact_id).to be_blank
          expect(page_after_move.contact_group_relation).to eq 'related'
          expect(page_after_move.contact_group_relation).to eq source_page.contact_group_relation
          expect(page_after_move.contact_charge).to eq source_page.contact_charge
          expect(page_after_move.contact_tel).to eq source_page.contact_tel
          expect(page_after_move.contact_fax).to eq source_page.contact_fax
          expect(page_after_move.contact_email).to eq source_page.contact_email
          expect(page_after_move.contact_link_url).to eq source_page.contact_link_url
          expect(page_after_move.contact_link_name).to eq source_page.contact_link_name
        end

        task.reload
        expect(task.state).to eq 'completed'
        expect(task.entity_logs.count).to eq 2
        expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['class']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['id']).to eq source_group.id.to_s
        expect(task.entity_logs[0]['changes']).to include('name')
        expect(task.entity_logs[1]['model']).to eq 'Cms::Page'
        expect(task.entity_logs[1]['class']).to eq 'Article::Page'
        expect(task.entity_logs[1]['id']).to eq '1'
        expect(task.entity_logs[1]['changes']).to be_present
      end
    end
  end
end
