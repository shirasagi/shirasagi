require 'spec_helper'

describe Chorg::MainRunner, dbscope: :example do
  let!(:root_group) { create(:revision_root_group) }
  let!(:site) { create(:cms_site, group_ids: [root_group.id]) }
  let!(:task) { Chorg::Task.create!(name: unique_id, site_id: site.id) }
  let(:job_opts) { { 'newly_created_group_to_site' => 'add' } }

  context "with move" do
    let!(:source_group) do
      create(
        :cms_group, name: "#{root_group.name}/#{unique_id}",
        contact_groups: [
          {
            main_state: "main", name: "name-#{unique_id}", contact_group_name: "contact_group_name-#{unique_id}",
            contact_tel: unique_tel, contact_fax: unique_tel, contact_email: unique_email,
            contact_link_url: "/#{unique_id}", contact_link_name: "link_name-#{unique_id}",
          },
          {
            main_state: nil, name: "name-#{unique_id}", contact_group_name: "contact_group_name-#{unique_id}",
            contact_tel: unique_tel, contact_fax: unique_tel, contact_email: unique_email,
            contact_link_url: "/#{unique_id}", contact_link_name: "link_name-#{unique_id}",
          }
        ]
      )
    end

    let!(:revision) { create(:revision, site_id: site.id) }
    let(:destination_contact1) do
      main_contact = source_group.contact_groups.where(main_state: "main").first
      if main_contact
        {
          _id: main_contact.id.to_s, main_state: "main", name: "main",
          contact_group_name: "name-#{unique_id}", contact_tel: unique_tel, contact_fax: unique_tel,
          contact_email: unique_email, contact_link_url: "/#{unique_id}/", contact_link_name: "link-#{unique_id}",
        }.with_indifferent_access
      end
    end
    let(:destination_contact2) do
      sub_contact = source_group.contact_groups.ne(main_state: "main").first
      if sub_contact
        {
          _id: sub_contact.id.to_s, main_state: nil, name: unique_id,
          contact_group_name: "name-#{unique_id}", contact_tel: unique_tel, contact_fax: unique_tel,
          contact_email: unique_email, contact_link_url: "/#{unique_id}/", contact_link_name: "link-#{unique_id}",
        }.with_indifferent_access
      end
    end
    let(:destination) do
      {
        name: "#{root_group.name}/#{unique_id}", order: rand(1..10).to_s,
        ldap_dn: "dc=dc-#{unique_id},dc=city,dc=example,dc=jp",
        contact_groups: [ destination_contact1, destination_contact2 ].compact
      }.with_indifferent_access
    end
    let!(:changeset) do
      create(:move_changeset, revision_id: revision.id, source: source_group, destinations: [ destination ])
    end

    let!(:article_node) { create(:article_node_page, cur_site: site) }
    let!(:article_page1) do
      main_contact = source_group.contact_groups.where(main_state: "main").first

      create(
        :article_page, cur_site: site, cur_node: article_node, group_ids: [ source_group.id ],
        contact_group_id: source_group.id, contact_group_contact_id: main_contact.id, contact_group_relation: "related",
        contact_charge: main_contact.contact_group_name, contact_tel: main_contact.contact_tel,
        contact_fax: main_contact.contact_fax, contact_email: main_contact.contact_email,
        contact_link_url: main_contact.contact_link_url, contact_link_name: main_contact.contact_link_name)
    end
    let!(:article_page2) do
      sub_contact = source_group.contact_groups.ne(main_state: "main").first

      create(
        :article_page, cur_site: site, cur_node: article_node, group_ids: [ source_group.id ],
        contact_group_id: source_group.id, contact_group_contact_id: sub_contact.id, contact_group_relation: "related",
        contact_charge: sub_contact.contact_group_name, contact_tel: sub_contact.contact_tel,
        contact_fax: sub_contact.contact_fax, contact_email: sub_contact.contact_email,
        contact_link_url: sub_contact.contact_link_url, contact_link_name: sub_contact.contact_link_name)
    end

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
            expect(group_after_move.name).not_to eq source_group.name
            expect(group_after_move.name).to eq destination["name"]
            expect(group_after_move.order.to_s).to eq destination["order"]
            expect(group_after_move.ldap_dn).to eq destination["ldap_dn"]

            expect(group_after_move.contact_groups).to have(source_group.contact_groups.count).items
            group_after_move.contact_groups.where(main_state: "main").first.tap do |main_contact_after_move|
              main_source_contact = source_group.contact_groups.where(main_state: "main").first
              expect(main_contact_after_move.id).to eq main_source_contact.id

              expect(main_contact_after_move.name).to eq destination_contact1["name"]
              expect(main_contact_after_move.main_state).to eq destination_contact1["main_state"]
              expect(main_contact_after_move.contact_group_name).to eq destination_contact1["contact_group_name"]
              expect(main_contact_after_move.contact_tel).to eq destination_contact1["contact_tel"]
              expect(main_contact_after_move.contact_fax).to eq destination_contact1["contact_fax"]
              expect(main_contact_after_move.contact_email).to eq destination_contact1["contact_email"]
              expect(main_contact_after_move.contact_link_url).to eq destination_contact1["contact_link_url"]
              expect(main_contact_after_move.contact_link_name).to eq destination_contact1["contact_link_name"]
            end
            group_after_move.contact_groups.ne(main_state: "main").first.tap do |sub_contact_after_move|
              sub_source_contact = source_group.contact_groups.ne(main_state: "main").first
              expect(sub_contact_after_move.id).to eq sub_source_contact.id

              expect(sub_contact_after_move.name).to eq destination_contact2["name"]
              expect(sub_contact_after_move.main_state).to eq destination_contact2["main_state"]
              expect(sub_contact_after_move.contact_group_name).to eq destination_contact2["contact_group_name"]
              expect(sub_contact_after_move.contact_tel).to eq destination_contact2["contact_tel"]
              expect(sub_contact_after_move.contact_fax).to eq destination_contact2["contact_fax"]
              expect(sub_contact_after_move.contact_email).to eq destination_contact2["contact_email"]
              expect(sub_contact_after_move.contact_link_url).to eq destination_contact2["contact_link_url"]
              expect(sub_contact_after_move.contact_link_name).to eq destination_contact2["contact_link_name"]
            end
          end

          # check page
          Cms::Page.find(article_page1.id).tap do |page_after_move|
            expect(page_after_move.group_ids).to eq [ source_group.id ]
            expect(page_after_move.filename).to eq article_page1.filename
            expect(page_after_move.contact_group_id).to eq source_group.id
            main_source_contact = source_group.contact_groups.where(main_state: "main").first
            expect(page_after_move.contact_group_contact_id).to eq main_source_contact.id
            expect(page_after_move.contact_charge).to eq destination_contact1["contact_group_name"]
            expect(page_after_move.contact_tel).to eq destination_contact1["contact_tel"]
            expect(page_after_move.contact_fax).to eq destination_contact1["contact_fax"]
            expect(page_after_move.contact_email).to eq destination_contact1["contact_email"]
            expect(page_after_move.contact_link_url).to eq destination_contact1["contact_link_url"]
            expect(page_after_move.contact_link_name).to eq destination_contact1["contact_link_name"]
          end
          Cms::Page.find(article_page2.id).tap do |page_after_move|
            expect(page_after_move.group_ids).to eq [ source_group.id ]
            expect(page_after_move.filename).to eq article_page2.filename
            expect(page_after_move.contact_group_id).to eq source_group.id
            sub_source_contact = source_group.contact_groups.ne(main_state: "main").first
            expect(page_after_move.contact_group_contact_id).to eq sub_source_contact.id
            expect(page_after_move.contact_charge).to eq destination_contact2["contact_group_name"]
            expect(page_after_move.contact_tel).to eq destination_contact2["contact_tel"]
            expect(page_after_move.contact_fax).to eq destination_contact2["contact_fax"]
            expect(page_after_move.contact_email).to eq destination_contact2["contact_email"]
            expect(page_after_move.contact_link_url).to eq destination_contact2["contact_link_url"]
            expect(page_after_move.contact_link_name).to eq destination_contact2["contact_link_name"]
          end

          task.reload
          expect(task.state).to eq 'completed'
          expect(task.entity_logs.count).to eq 4
          task.entity_logs[0].tap do |entity_log|
            expect(entity_log['model']).to eq 'Cms::Group'
            expect(entity_log['class']).to eq 'Cms::Group'
            expect(entity_log['id']).to eq source_group.id.to_s
            expect(entity_log['changes']).to include('name')
          end
          task.entity_logs[1].tap do |entity_log|
            expect(entity_log['model']).to eq 'Cms::Node'
            expect(entity_log['class']).to eq 'Article::Node::Page'
            expect(entity_log['id']).to eq article_node.id.to_s
            expect(entity_log['changes']).to include('conditions')
          end
          task.entity_logs[2].tap do |entity_log|
            expect(entity_log['model']).to eq 'Cms::Page'
            expect(entity_log['class']).to eq 'Article::Page'
            expect(entity_log['id']).to eq article_page1.id.to_s
            expect(entity_log['changes']).to include(
              'contact_tel', 'contact_fax', 'contact_email', 'contact_link_url', 'contact_link_name'
            )
          end
          task.entity_logs[3].tap do |entity_log|
            expect(entity_log['model']).to eq 'Cms::Page'
            expect(entity_log['class']).to eq 'Article::Page'
            expect(entity_log['id']).to eq article_page2.id.to_s
            expect(entity_log['changes']).to include(
              'contact_tel', 'contact_fax', 'contact_email', 'contact_link_url', 'contact_link_name'
            )
          end
        end
      end

      context "contact_group_relation is 'unrelated'" do
        before do
          article_page1.update!(contact_group_relation: "unrelated")
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
            expect(group_after_move.name).not_to eq source_group.name
            expect(group_after_move.name).to eq destination["name"]
            expect(group_after_move.order.to_s).to eq destination["order"]
            expect(group_after_move.ldap_dn).to eq destination["ldap_dn"]

            expect(group_after_move.contact_groups).to have(source_group.contact_groups.count).items
            group_after_move.contact_groups.where(main_state: "main").first.tap do |main_contact_after_move|
              main_source_contact = source_group.contact_groups.where(main_state: "main").first
              expect(main_contact_after_move.id).to eq main_source_contact.id

              expect(main_contact_after_move.name).to eq destination_contact1["name"]
              expect(main_contact_after_move.main_state).to eq destination_contact1["main_state"]
              expect(main_contact_after_move.contact_group_name).to eq destination_contact1["contact_group_name"]
              expect(main_contact_after_move.contact_tel).to eq destination_contact1["contact_tel"]
              expect(main_contact_after_move.contact_fax).to eq destination_contact1["contact_fax"]
              expect(main_contact_after_move.contact_email).to eq destination_contact1["contact_email"]
              expect(main_contact_after_move.contact_link_url).to eq destination_contact1["contact_link_url"]
              expect(main_contact_after_move.contact_link_name).to eq destination_contact1["contact_link_name"]
            end
          end

          # check page
          Cms::Page.find(article_page1.id).tap do |page_after_move|
            expect(page_after_move.group_ids).to eq [ source_group.id ]
            expect(page_after_move.filename).to eq article_page1.filename
            expect(page_after_move.contact_group_id).to eq source_group.id
            main_source_contact = source_group.contact_groups.where(main_state: "main").first
            expect(page_after_move.contact_group_contact_id).to eq main_source_contact.id
            expect(page_after_move.contact_charge).to eq article_page1.contact_charge
            expect(page_after_move.contact_tel).to eq article_page1.contact_tel
            expect(page_after_move.contact_fax).to eq article_page1.contact_fax
            expect(page_after_move.contact_email).to eq article_page1.contact_email
            expect(page_after_move.contact_link_url).to eq article_page1.contact_link_url
            expect(page_after_move.contact_link_name).to eq article_page1.contact_link_name
          end

          task.reload
          expect(task.state).to eq 'completed'
          expect(task.entity_logs.count).to eq 4
          task.entity_logs[0].tap do |entity_log|
            expect(entity_log['model']).to eq 'Cms::Group'
            expect(entity_log['class']).to eq 'Cms::Group'
            expect(entity_log['id']).to eq source_group.id.to_s
            expect(entity_log['changes']).to include('name')
          end
          task.entity_logs[1].tap do |entity_log|
            expect(entity_log['model']).to eq 'Cms::Node'
            expect(entity_log['class']).to eq 'Article::Node::Page'
            expect(entity_log['id']).to eq article_node.id.to_s
            expect(entity_log['changes']).to include('conditions')
          end
          task.entity_logs[2].tap do |entity_log|
            expect(entity_log['model']).to eq 'Cms::Page'
            expect(entity_log['class']).to eq 'Article::Page'
            expect(entity_log['id']).to eq article_page1.id.to_s
            expect(entity_log['changes']).to be_present
          end
          task.entity_logs[3].tap do |entity_log|
            expect(entity_log['model']).to eq 'Cms::Page'
            expect(entity_log['class']).to eq 'Article::Page'
            expect(entity_log['id']).to eq article_page2.id.to_s
            expect(entity_log['changes']).to be_present
          end
        end
      end
    end

    context "with only move name" do
      let!(:changeset) { create(:move_changeset_only_name, revision_id: revision.id, source: source_group) }

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
        Cms::Page.find(article_page1.id).tap do |page_after_move|
          expect(page_after_move.group_ids).to eq [ source_group.id ]
          expect(page_after_move.filename).to eq article_page1.filename
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
        expect(task.entity_logs.count).to eq 4
        task.entity_logs[0].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Group'
          expect(entity_log['id']).to eq source_group.id.to_s
          expect(entity_log['changes']).to include("name")
        end
        task.entity_logs[1].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Node'
          expect(entity_log['class']).to eq 'Article::Node::Page'
          expect(entity_log['id']).to eq article_node.id.to_s
          expect(entity_log['changes']).to be_present
        end
        task.entity_logs[2].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Page'
          expect(entity_log['class']).to eq 'Article::Page'
          expect(entity_log['id']).to eq article_page1.id.to_s
          expect(entity_log['changes']).to be_present
        end
        task.entity_logs[3].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Page'
          expect(entity_log['class']).to eq 'Article::Page'
          expect(entity_log['id']).to eq article_page2.id.to_s
          expect(entity_log['changes']).to be_present
        end
      end
    end

    context "with workflow approving Article::Page" do
      let!(:user1) do
        create(:cms_user, name: unique_id.to_s, email: "#{unique_id}@example.jp",
               group_ids: [source_group.id], cms_role_ids: [cms_role.id])
      end
      let!(:user2) do
        create(:cms_user, name: unique_id.to_s, email: "#{unique_id}@example.jp",
               group_ids: [source_group.id], cms_role_ids: [cms_role.id])
      end
      let!(:article_page1) do
        page = build(:revision_page, cur_site: site, cur_node: article_node, group: source_group,
               workflow_user_id: user1.id, workflow_state: "request", workflow_comment: "",
               workflow_approvers: [{level: 1, user_id: user2.id, state: "request", comment: ""}],
               workflow_required_counts: [false])
        page.cur_site = site
        page.save!
        page
      end

      it do
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
        Cms::Page.find(article_page1.id).tap do |page_after_move|
          expect(page_after_move.group_ids).to eq [ source_group.id ]
          expect(page_after_move.filename).to eq article_page1.filename
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
        expect(task.entity_logs.count).to eq 4
        task.entity_logs[0].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Group'
          expect(entity_log['class']).to eq 'Cms::Group'
          expect(entity_log['id']).to eq source_group.id.to_s
          expect(entity_log['changes']).to include(
            'name', 'contact_tel', 'contact_fax', 'contact_email', 'contact_link_url', 'contact_link_name'
          )
        end
        task.entity_logs[1].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Node'
          expect(entity_log['class']).to eq 'Article::Node::Page'
          expect(entity_log['id']).to eq '1'
          expect(entity_log['changes']).to be_present
        end
        task.entity_logs[2].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Page'
          expect(entity_log['class']).to eq 'Article::Page'
          expect(entity_log['id']).to eq article_page1.id.to_s
          expect(entity_log['changes']).to include(
            'contact_tel', 'contact_fax', 'contact_email', 'contact_link_url', 'contact_link_name'
          )
        end
        task.entity_logs[3].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Page'
          expect(entity_log['class']).to eq 'Article::Page'
          expect(entity_log['id']).to eq article_page2.id.to_s
          expect(entity_log['changes']).to include(
            'contact_tel', 'contact_fax', 'contact_email', 'contact_link_url', 'contact_link_name'
          )
        end
      end
    end

    context 'グループの連絡先: 0件 → 1件, ページの連動: 有効' do
      let!(:source_group) { create(:cms_group, name: "#{root_group.name}/グループ#{unique_id}") }
      let(:destination_contact1) do
        {
          main_state: "main", name: unique_id, contact_group_name: "name-#{unique_id}",
          contact_tel: unique_tel, contact_fax: unique_tel, contact_email: unique_email,
          contact_link_url: "/#{unique_id}/", contact_link_name: "link-#{unique_id}",
        }.with_indifferent_access
      end
      let!(:article_page1) do
        create(
          :article_page, cur_site: site, cur_node: article_node,
          contact_group: source_group, contact_charge: source_group.trailing_name,
          contact_tel: unique_tel, contact_fax: unique_tel, contact_email: unique_email,
          contact_link_url: "/#{unique_id}/", contact_link_name: "link_name-#{unique_id}")
      end
      let!(:article_page2) do
        create(
          :article_page, cur_site: site, cur_node: article_node,
          contact_group: source_group, contact_charge: source_group.trailing_name,
          contact_tel: unique_tel, contact_fax: unique_tel, contact_email: unique_email,
          contact_link_url: "/#{unique_id}/", contact_link_name: "link_name-#{unique_id}")
      end

      it do
        expect(source_group.contact_groups.count).to eq 0
        expect(article_page1.contact_group_id).to eq source_group.id
        expect(article_page1.contact_group_contact_id).to be_blank

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
          expect(group_after_move.name).not_to eq source_group.name
          expect(group_after_move.order.to_s).to eq destination["order"]
          expect(group_after_move.ldap_dn).to eq destination["ldap_dn"]

          expect(group_after_move.contact_groups).not_to have(source_group.contact_groups.count).items
          expect(group_after_move.contact_groups).to have(1).items
          group_after_move.contact_groups[0].tap do |contact_after_move|
            expect(contact_after_move.name).to eq destination_contact1["name"]
            expect(contact_after_move.main_state).to eq destination_contact1["main_state"]
            expect(contact_after_move.contact_group_name).to eq destination_contact1["contact_group_name"]
            expect(contact_after_move.contact_tel).to eq destination_contact1["contact_tel"]
            expect(contact_after_move.contact_fax).to eq destination_contact1["contact_fax"]
            expect(contact_after_move.contact_email).to eq destination_contact1["contact_email"]
            expect(contact_after_move.contact_link_url).to eq destination_contact1["contact_link_url"]
            expect(contact_after_move.contact_link_name).to eq destination_contact1["contact_link_name"]
          end
        end

        # check page
        Cms::Page.find(article_page1.id).tap do |page_after_move|
          expect(page_after_move.contact_group_id).to eq source_group.id
          expect(page_after_move.contact_group_contact_id).to be_blank
          expect(page_after_move.contact_charge).to eq article_page1.contact_charge
          expect(page_after_move.contact_tel).to eq article_page1.contact_tel
          expect(page_after_move.contact_fax).to eq article_page1.contact_fax
          expect(page_after_move.contact_email).to eq article_page1.contact_email
          expect(page_after_move.contact_link_url).to eq article_page1.contact_link_url
          expect(page_after_move.contact_link_name).to eq article_page1.contact_link_name
        end

        task.reload
        expect(task.state).to eq 'completed'
        expect(task.entity_logs.count).to eq 4
        task.entity_logs[0].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Group'
          expect(entity_log['class']).to eq 'Cms::Group'
          expect(entity_log['id']).to eq source_group.id.to_s
          expect(entity_log['changes']).to include(
            'name', 'contact_tel', 'contact_fax', 'contact_email', 'contact_link_url', 'contact_link_name'
          )
        end
        task.entity_logs[1].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Node'
          expect(entity_log['class']).to eq 'Article::Node::Page'
          expect(entity_log['id']).to eq '1'
          expect(entity_log['changes']).to be_present
        end
        task.entity_logs[2].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Page'
          expect(entity_log['class']).to eq 'Article::Page'
          expect(entity_log['id']).to eq article_page1.id.to_s
          expect(entity_log['changes']).to be_present
        end
        task.entity_logs[3].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Page'
          expect(entity_log['class']).to eq 'Article::Page'
          expect(entity_log['id']).to eq article_page2.id.to_s
          expect(entity_log['changes']).to be_present
        end
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
        Cms::Page.find(article_page1.id).tap do |page_after_move|
          expect(page_after_move.contact_group_id).to eq source_group.id
          expect(page_after_move.contact_group_contact_id).to be_blank
          expect(page_after_move.contact_group_relation).to eq 'related'
          expect(page_after_move.contact_group_relation).to eq article_page1.contact_group_relation
          expect(page_after_move.contact_charge).to eq article_page1.contact_charge
          expect(page_after_move.contact_tel).to eq article_page1.contact_tel
          expect(page_after_move.contact_fax).to eq article_page1.contact_fax
          expect(page_after_move.contact_email).to eq article_page1.contact_email
          expect(page_after_move.contact_link_url).to eq article_page1.contact_link_url
          expect(page_after_move.contact_link_name).to eq article_page1.contact_link_name
        end

        task.reload
        expect(task.state).to eq 'completed'
        expect(task.entity_logs.count).to eq 4
        task.entity_logs[0].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Group'
          expect(entity_log['class']).to eq 'Cms::Group'
          expect(entity_log['id']).to eq source_group.id.to_s
          expect(entity_log['changes']).to include('name')
        end
        task.entity_logs[1].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Node'
          expect(entity_log['class']).to eq 'Article::Node::Page'
          expect(entity_log['id']).to eq '1'
          expect(entity_log['changes']).to be_present
        end
        task.entity_logs[2].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Page'
          expect(entity_log['class']).to eq 'Article::Page'
          expect(entity_log['id']).to eq article_page1.id.to_s
          expect(entity_log['changes']).to be_present
        end
        task.entity_logs[3].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Page'
          expect(entity_log['class']).to eq 'Article::Page'
          expect(entity_log['id']).to eq article_page2.id.to_s
          expect(entity_log['changes']).to be_present
        end
      end
    end

    context 'unable to move to existing group' do
      let!(:group2) { create(:revision_new_group, order: 20) }
      let(:destination) do
        {
          name: group2.name, order: group2.order.to_s, ldap_dn: group2.ldap_dn,
          contact_groups: [ destination_contact1, destination_contact2 ].compact
        }.with_indifferent_access
      end

      let!(:article_page3) do
        main_contact = group2.contact_groups.where(main_state: "main").first

        create(
          :article_page, cur_site: site, cur_node: article_node, group_ids: [ source_group.id ],
          contact_group_id: source_group.id, contact_group_contact_id: main_contact.id, contact_group_relation: "related",
          contact_charge: main_contact.contact_group_name, contact_tel: main_contact.contact_tel,
          contact_fax: main_contact.contact_fax, contact_email: main_contact.contact_email,
          contact_link_url: main_contact.contact_link_url, contact_link_name: main_contact.contact_link_name)
      end

      it do
        # execute
        job = described_class.bind(site_id: site.id, task_id: task.id)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[移動] 成功: 0, 失敗: 1\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        # check group
        Cms::Group.where(id: source_group.id).first.tap do |group|
          expect(group.name).to eq source_group.name
          expect(group.order).to eq source_group.order
          expect(group.ldap_dn).to eq source_group.ldap_dn

          expect(group.contact_groups).to have(source_group.contact_groups.count).items
          group.contact_groups.where(main_state: "main").first.tap do |main_contact|
            main_source_contact = source_group.contact_groups.where(main_state: "main").first
            expect(main_contact.id).to eq main_source_contact.id
            expect(main_contact.name).to eq main_source_contact.name
            expect(main_contact.main_state).to eq main_source_contact.main_state
            expect(main_contact.contact_group_name).to eq main_source_contact.contact_group_name
            expect(main_contact.contact_tel).to eq main_source_contact.contact_tel
            expect(main_contact.contact_fax).to eq main_source_contact.contact_fax
            expect(main_contact.contact_email).to eq main_source_contact.contact_email
            expect(main_contact.contact_link_url).to eq main_source_contact.contact_link_url
            expect(main_contact.contact_link_name).to eq main_source_contact.contact_link_name
          end
          group.contact_groups.ne(main_state: "main").first.tap do |sub_contact|
            sub_source_contact = source_group.contact_groups.ne(main_state: "main").first
            expect(sub_contact.id).to eq sub_source_contact.id
            expect(sub_contact.name).to eq sub_source_contact.name
            expect(sub_contact.main_state).to eq sub_source_contact.main_state
            expect(sub_contact.contact_group_name).to eq sub_source_contact.contact_group_name
            expect(sub_contact.contact_tel).to eq sub_source_contact.contact_tel
            expect(sub_contact.contact_fax).to eq sub_source_contact.contact_fax
            expect(sub_contact.contact_email).to eq sub_source_contact.contact_email
            expect(sub_contact.contact_link_url).to eq sub_source_contact.contact_link_url
            expect(sub_contact.contact_link_name).to eq sub_source_contact.contact_link_name
          end
        end
        Cms::Group.where(id: group2.id).first.tap do |group|
          expect(group.name).to eq group2.name
          expect(group.order).to eq group2.order
          expect(group.ldap_dn).to eq group2.ldap_dn

          expect(group.contact_groups).to have(group2.contact_groups.count).items
          group.contact_groups.where(main_state: "main").first.tap do |main_contact|
            main_source_contact = group2.contact_groups.where(main_state: "main").first
            expect(main_contact.id).to eq main_source_contact.id
            expect(main_contact.name).to eq main_source_contact.name
            expect(main_contact.main_state).to eq main_source_contact.main_state
            expect(main_contact.contact_group_name).to eq main_source_contact.contact_group_name
            expect(main_contact.contact_tel).to eq main_source_contact.contact_tel
            expect(main_contact.contact_fax).to eq main_source_contact.contact_fax
            expect(main_contact.contact_email).to eq main_source_contact.contact_email
            expect(main_contact.contact_link_url).to eq main_source_contact.contact_link_url
            expect(main_contact.contact_link_name).to eq main_source_contact.contact_link_name
          end
        end
      end
    end
  end

  context "SS::Contact#name が組織変更の前後で一致していれば「ページ-連絡先」連携が切れない" do
    let!(:source_group) do
      create(
        :cms_group, name: "#{root_group.name}/#{unique_id}",
        contact_groups: [
          {
            main_state: "main", name: "name-#{unique_id}", contact_group_name: "contact_group_name-#{unique_id}",
            contact_tel: unique_tel, contact_fax: unique_tel, contact_email: unique_email,
            contact_link_url: "/#{unique_id}", contact_link_name: "link_name-#{unique_id}",
          },
          {
            main_state: nil, name: "name-#{unique_id}", contact_group_name: "contact_group_name-#{unique_id}",
            contact_tel: unique_tel, contact_fax: unique_tel, contact_email: unique_email,
            contact_link_url: "/#{unique_id}", contact_link_name: "link_name-#{unique_id}",
          }
        ]
      )
    end

    let!(:revision) { create(:revision, site_id: site.id) }
    let(:destination_contact1) do
      main_contact = source_group.contact_groups.where(main_state: "main").first

      # name を一致させる
      {
        _id: BSON::ObjectId.new.to_s, main_state: "main", name: main_contact.name,
        contact_group_name: "name-#{unique_id}", contact_tel: unique_tel, contact_fax: unique_tel,
        contact_email: unique_email, contact_link_url: "/#{unique_id}/", contact_link_name: "link-#{unique_id}",
      }.with_indifferent_access
    end
    let(:destination_contact2) do
      sub_contact = source_group.contact_groups.ne(main_state: "main").first

      # name を一致させる
      {
        _id: BSON::ObjectId.new.to_s, main_state: nil, name: sub_contact.name,
        contact_group_name: "name-#{unique_id}", contact_tel: unique_tel, contact_fax: unique_tel,
        contact_email: unique_email, contact_link_url: "/#{unique_id}/", contact_link_name: "link-#{unique_id}",
      }.with_indifferent_access
    end
    let(:destination) do
      {
        name: "#{root_group.name}/#{unique_id}", order: rand(1..10).to_s,
        ldap_dn: "dc=dc-#{unique_id},dc=city,dc=example,dc=jp",
        contact_groups: [ destination_contact1, destination_contact2 ].compact
      }.with_indifferent_access
    end
    let!(:changeset) do
      create(:move_changeset, revision_id: revision.id, source: source_group, destinations: [ destination ])
    end

    let!(:article_node) { create(:article_node_page, cur_site: site) }
    let!(:article_page1) do
      main_contact = source_group.contact_groups.where(main_state: "main").first

      create(
        :article_page, cur_site: site, cur_node: article_node, group_ids: [ source_group.id ],
        contact_group_id: source_group.id, contact_group_contact_id: main_contact.id, contact_group_relation: "related",
        contact_charge: main_contact.contact_group_name, contact_tel: main_contact.contact_tel,
        contact_fax: main_contact.contact_fax, contact_email: main_contact.contact_email,
        contact_link_url: main_contact.contact_link_url, contact_link_name: main_contact.contact_link_name)
    end
    let!(:article_page2) do
      sub_contact = source_group.contact_groups.ne(main_state: "main").first

      create(
        :article_page, cur_site: site, cur_node: article_node, group_ids: [ source_group.id ],
        contact_group_id: source_group.id, contact_group_contact_id: sub_contact.id, contact_group_relation: "related",
        contact_charge: sub_contact.contact_group_name, contact_tel: sub_contact.contact_tel,
        contact_fax: sub_contact.contact_fax, contact_email: sub_contact.contact_email,
        contact_link_url: sub_contact.contact_link_url, contact_link_name: sub_contact.contact_link_name)
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
        expect(group_after_move.contact_groups).to have(source_group.contact_groups.count).items
        group_after_move.contact_groups.where(main_state: "main").first.tap do |main_contact_after_move|
          main_source_contact = source_group.contact_groups.where(main_state: "main").first
          # name が組織変更の前後で一致しているので、ID に変化はないはず。
          expect(main_contact_after_move.id).to eq main_source_contact.id
        end
        group_after_move.contact_groups.ne(main_state: "main").first.tap do |sub_contact_after_move|
          sub_source_contact = source_group.contact_groups.ne(main_state: "main").first
          # name が組織変更の前後で一致しているので、ID に変化はないはず。
          expect(sub_contact_after_move.id).to eq sub_source_contact.id
        end
      end

      # check page
      Cms::Page.find(article_page1.id).tap do |page_after_move|
        # expect(page_after_move.group_ids).to eq [ source_group.id ]
        # expect(page_after_move.filename).to eq article_page1.filename
        expect(page_after_move.contact_group_id).to eq source_group.id
        main_source_contact = source_group.contact_groups.where(main_state: "main").first
        expect(page_after_move.contact_group_contact_id).to eq main_source_contact.id
        expect(page_after_move.contact_charge).to eq destination_contact1["contact_group_name"]
        expect(page_after_move.contact_tel).to eq destination_contact1["contact_tel"]
        expect(page_after_move.contact_fax).to eq destination_contact1["contact_fax"]
        expect(page_after_move.contact_email).to eq destination_contact1["contact_email"]
        expect(page_after_move.contact_link_url).to eq destination_contact1["contact_link_url"]
        expect(page_after_move.contact_link_name).to eq destination_contact1["contact_link_name"]
      end
      Cms::Page.find(article_page2.id).tap do |page_after_move|
        # expect(page_after_move.group_ids).to eq [ source_group.id ]
        # expect(page_after_move.filename).to eq article_page2.filename
        expect(page_after_move.contact_group_id).to eq source_group.id
        sub_source_contact = source_group.contact_groups.ne(main_state: "main").first
        expect(page_after_move.contact_group_contact_id).to eq sub_source_contact.id
        expect(page_after_move.contact_charge).to eq destination_contact2["contact_group_name"]
        expect(page_after_move.contact_tel).to eq destination_contact2["contact_tel"]
        expect(page_after_move.contact_fax).to eq destination_contact2["contact_fax"]
        expect(page_after_move.contact_email).to eq destination_contact2["contact_email"]
        expect(page_after_move.contact_link_url).to eq destination_contact2["contact_link_url"]
        expect(page_after_move.contact_link_name).to eq destination_contact2["contact_link_name"]
      end
    end
  end
end
