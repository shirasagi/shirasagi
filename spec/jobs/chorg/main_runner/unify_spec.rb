require 'spec_helper'

describe Chorg::MainRunner, dbscope: :example do
  let!(:root_group) { create(:revision_root_group) }
  let!(:site) { create(:cms_site, group_ids: [root_group.id]) }
  let!(:task) { Chorg::Task.create!(name: unique_id, site_id: site.id) }
  let(:job_opts) { { 'newly_created_group_to_site' => 'add' } }

  context "with unify" do
    context "with all available attributes" do
      let!(:source_group1) do
        create(
          :cms_group, name: "#{root_group.name}/#{unique_id}", order: 10,
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
      let!(:source_group2) do
        create(
          :cms_group, name: "#{root_group.name}/#{unique_id}", order: 20,
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

      let!(:user1) { create(:cms_user, name: unique_id, email: unique_email, group_ids: [ source_group1.id ]) }
      let!(:user2) { create(:cms_user, name: unique_id, email: unique_email, group_ids: [ source_group2.id ]) }

      let!(:revision) { create(:revision, site_id: site.id) }
      let(:destination_contact1) do
        # source_group1 の主連絡先 --> destination の主連絡先
        main_contact = source_group1.contact_groups.where(main_state: "main").first
        {
          _id: main_contact.id.to_s, main_state: "main", name: "name-#{unique_id}",
          contact_group_name: "name-#{unique_id}", contact_tel: unique_tel, contact_fax: unique_tel,
          contact_email: unique_email, contact_link_url: "/#{unique_id}/", contact_link_name: "link-#{unique_id}",
        }.with_indifferent_access
      end
      let(:destination_contact2) do
        # source_group1 のサブ連絡先 --> destination のサブ連絡先
        sub_contact = source_group1.contact_groups.ne(main_state: "main").first
        {
          _id: sub_contact.id.to_s, main_state: nil, name: "name-#{unique_id}",
          contact_group_name: "name-#{unique_id}", contact_tel: unique_tel, contact_fax: unique_tel,
          contact_email: unique_email, contact_link_url: "/#{unique_id}/", contact_link_name: "link-#{unique_id}",
        }.with_indifferent_access
      end
      let(:destination_contact3) do
        # source_group2 の主連絡先 --> destination のサブ連絡先
        main_contact = source_group2.contact_groups.where(main_state: "main").first
        {
          _id: main_contact.id.to_s, main_state: nil, name: "name-#{unique_id}",
          contact_group_name: "name-#{unique_id}", contact_tel: unique_tel, contact_fax: unique_tel,
          contact_email: unique_email, contact_link_url: "/#{unique_id}/", contact_link_name: "link-#{unique_id}",
        }.with_indifferent_access
      end
      let(:destination_contact4) do
        # source_group2 のサブ連絡先 --> destination のサブ連絡先
        sub_contact = source_group2.contact_groups.ne(main_state: "main").first
        {
          _id: sub_contact.id.to_s, main_state: nil, name: "name-#{unique_id}",
          contact_group_name: "name-#{unique_id}", contact_tel: unique_tel, contact_fax: unique_tel,
          contact_email: unique_email, contact_link_url: "/#{unique_id}/", contact_link_name: "link-#{unique_id}",
        }.with_indifferent_access
      end
      let(:destination) do
        {
          name: "#{root_group.name}/#{unique_id}", order: rand(1..10).to_s,
          ldap_dn: "dc=dc-#{unique_id},dc=city,dc=example,dc=jp",
          contact_groups: [ destination_contact1, destination_contact2, destination_contact3, destination_contact4 ]
        }.with_indifferent_access
      end
      let!(:changeset) do
        create(
          :unify_changeset, revision_id: revision.id, sources: [ source_group1, source_group2 ],
          destinations: [ destination ])
      end

      let!(:article_node) { create(:article_node_page, cur_site: site) }
      let!(:article_page1) do
        # source_group1 の主連絡先
        main_contact = source_group1.contact_groups.where(main_state: "main").first
        create(
          :article_page, cur_site: site, cur_node: article_node, group_ids: [ source_group1.id, source_group2.id ],
          contact_group_id: source_group1.id, contact_group_contact_id: main_contact.id, contact_group_relation: "related",
          contact_charge: main_contact.contact_group_name, contact_tel: main_contact.contact_tel,
          contact_fax: main_contact.contact_fax, contact_email: main_contact.contact_email,
          contact_link_url: main_contact.contact_link_url, contact_link_name: main_contact.contact_link_name)
      end
      let!(:article_page2) do
        # source_group1 のサブ連絡先
        sub_contact = source_group1.contact_groups.ne(main_state: "main").first
        create(
          :article_page, cur_site: site, cur_node: article_node, group_ids: [ source_group1.id, source_group2.id ],
          contact_group_id: source_group1.id, contact_group_contact_id: sub_contact.id, contact_group_relation: "related",
          contact_charge: sub_contact.contact_group_name, contact_tel: sub_contact.contact_tel,
          contact_fax: sub_contact.contact_fax, contact_email: sub_contact.contact_email,
          contact_link_url: sub_contact.contact_link_url, contact_link_name: sub_contact.contact_link_name)
      end
      let!(:article_page3) do
        # source_group2 の主連絡先
        main_contact = source_group2.contact_groups.where(main_state: "main").first
        create(
          :article_page, cur_site: site, cur_node: article_node, group_ids: [ source_group1.id, source_group2.id ],
          contact_group_id: source_group1.id, contact_group_contact_id: main_contact.id, contact_group_relation: "related",
          contact_charge: main_contact.contact_group_name, contact_tel: main_contact.contact_tel,
          contact_fax: main_contact.contact_fax, contact_email: main_contact.contact_email,
          contact_link_url: main_contact.contact_link_url, contact_link_name: main_contact.contact_link_name)
      end
      let!(:article_page4) do
        # source_group2 のサブ連絡先
        sub_contact = source_group2.contact_groups.ne(main_state: "main").first
        create(
          :article_page, cur_site: site, cur_node: article_node, group_ids: [ source_group1.id, source_group2.id ],
          contact_group_id: source_group1.id, contact_group_contact_id: sub_contact.id, contact_group_relation: "related",
          contact_charge: sub_contact.contact_group_name, contact_tel: sub_contact.contact_tel,
          contact_fax: sub_contact.contact_fax, contact_email: sub_contact.contact_email,
          contact_link_url: sub_contact.contact_link_url, contact_link_name: sub_contact.contact_link_name)
      end

      it do
        # execute
        job = described_class.bind(site_id: site.id, task_id: task.id, user_id: user1.id)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[統合] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        # check group
        expect { Cms::Group.find(source_group2.id) }.to raise_error Mongoid::Errors::DocumentNotFound
        expect { Cms::Group.find(source_group2.name) }.to raise_error Mongoid::Errors::DocumentNotFound
        group_after_unify = Cms::Group.find(source_group1.id).tap do |group_after_unify|
          destination0 = changeset.destinations[0]
          expect(group_after_unify.name).to eq destination0["name"]
          expect(group_after_unify.order.to_s).to eq destination0["order"]
          expect(group_after_unify.ldap_dn).to eq destination0["ldap_dn"]
          expect(group_after_unify.contact_groups.count).to eq 4
          group_after_unify.contact_groups.where(id: destination_contact1[:_id]).first.tap do |contact_after_unify|
            expect(contact_after_unify.name).to eq destination_contact1["name"]
            expect(contact_after_unify.main_state).to eq destination_contact1["main_state"]
            expect(contact_after_unify.contact_group_name).to eq destination_contact1["contact_group_name"]
            expect(contact_after_unify.contact_tel).to eq destination_contact1["contact_tel"]
            expect(contact_after_unify.contact_fax).to eq destination_contact1["contact_fax"]
            expect(contact_after_unify.contact_email).to eq destination_contact1["contact_email"]
            expect(contact_after_unify.contact_link_url).to eq destination_contact1["contact_link_url"]
            expect(contact_after_unify.contact_link_name).to eq destination_contact1["contact_link_name"]
          end
          group_after_unify.contact_groups.where(id: destination_contact2[:_id]).first.tap do |contact_after_unify|
            expect(contact_after_unify.name).to eq destination_contact2["name"]
            expect(contact_after_unify.main_state).to eq destination_contact2["main_state"]
            expect(contact_after_unify.contact_group_name).to eq destination_contact2["contact_group_name"]
            expect(contact_after_unify.contact_tel).to eq destination_contact2["contact_tel"]
            expect(contact_after_unify.contact_fax).to eq destination_contact2["contact_fax"]
            expect(contact_after_unify.contact_email).to eq destination_contact2["contact_email"]
            expect(contact_after_unify.contact_link_url).to eq destination_contact2["contact_link_url"]
            expect(contact_after_unify.contact_link_name).to eq destination_contact2["contact_link_name"]
          end
          group_after_unify.contact_groups.where(id: destination_contact3[:_id]).first.tap do |contact_after_unify|
            expect(contact_after_unify.name).to eq destination_contact3["name"]
            expect(contact_after_unify.main_state).to eq destination_contact3["main_state"]
            expect(contact_after_unify.contact_group_name).to eq destination_contact3["contact_group_name"]
            expect(contact_after_unify.contact_tel).to eq destination_contact3["contact_tel"]
            expect(contact_after_unify.contact_fax).to eq destination_contact3["contact_fax"]
            expect(contact_after_unify.contact_email).to eq destination_contact3["contact_email"]
            expect(contact_after_unify.contact_link_url).to eq destination_contact3["contact_link_url"]
            expect(contact_after_unify.contact_link_name).to eq destination_contact3["contact_link_name"]
          end
          group_after_unify.contact_groups.where(id: destination_contact4[:_id]).first.tap do |contact_after_unify|
            expect(contact_after_unify.name).to eq destination_contact4["name"]
            expect(contact_after_unify.main_state).to eq destination_contact4["main_state"]
            expect(contact_after_unify.contact_group_name).to eq destination_contact4["contact_group_name"]
            expect(contact_after_unify.contact_tel).to eq destination_contact4["contact_tel"]
            expect(contact_after_unify.contact_fax).to eq destination_contact4["contact_fax"]
            expect(contact_after_unify.contact_email).to eq destination_contact4["contact_email"]
            expect(contact_after_unify.contact_link_url).to eq destination_contact4["contact_link_url"]
            expect(contact_after_unify.contact_link_name).to eq destination_contact4["contact_link_name"]
          end
        end

        # check page
        Cms::Page.find(article_page1.id).tap do |page_after_unify|
          expect(page_after_unify.group_ids).to eq [ group_after_unify.id ]
          expect(page_after_unify.contact_group_id).to eq group_after_unify.id
          expect(page_after_unify.contact_tel).to eq group_after_unify.contact_tel
          expect(page_after_unify.contact_fax).to eq group_after_unify.contact_fax
          expect(page_after_unify.contact_email).to eq group_after_unify.contact_email
          expect(page_after_unify.contact_link_url).to eq group_after_unify.contact_link_url
          expect(page_after_unify.contact_link_name).to eq group_after_unify.contact_link_name
        end

        user1.reload
        expect(user1.group_ids).to eq([ group_after_unify.id ])
        user2.reload
        expect(user2.group_ids).to eq([ group_after_unify.id ])

        task.reload
        expect(task.state).to eq 'completed'
        expect(task.entity_logs.count).to eq 9
        task.entity_logs[0].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Group'
          expect(entity_log['class']).to eq 'Cms::Group'
          expect(entity_log['id']).to eq source_group1.id.to_s
          expect(entity_log['changes']).to include('name', 'contact_email')
        end
        task.entity_logs[1].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Site'
          expect(entity_log['class']).to eq 'Cms::Site'
          expect(entity_log['id']).to eq site.id.to_s
          expect(entity_log['changes']).to include('group_ids')
        end
        task.entity_logs[2].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::User'
          expect(entity_log['class']).to eq 'Cms::User'
          expect(entity_log['id']).to eq user2.id.to_s
          expect(entity_log['changes']).to include('group_ids')
        end
        task.entity_logs[3].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Node'
          expect(entity_log['class']).to eq 'Article::Node::Page'
          expect(entity_log['id']).to eq article_node.id.to_s
          expect(entity_log['changes']).to include("conditions")
        end
        task.entity_logs[4].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Page'
          expect(entity_log['class']).to eq 'Article::Page'
          expect(entity_log['id']).to eq article_page1.id.to_s
          expect(entity_log['changes']).to include("group_ids")
        end
        task.entity_logs[5].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Page'
          expect(entity_log['class']).to eq 'Article::Page'
          expect(entity_log['id']).to eq article_page2.id.to_s
          expect(entity_log['changes']).to include("group_ids")
        end
        task.entity_logs[6].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Page'
          expect(entity_log['class']).to eq 'Article::Page'
          expect(entity_log['id']).to eq article_page3.id.to_s
          expect(entity_log['changes']).to include("group_ids")
        end
        task.entity_logs[7].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Page'
          expect(entity_log['class']).to eq 'Article::Page'
          expect(entity_log['id']).to eq article_page4.id.to_s
          expect(entity_log['changes']).to include("group_ids")
        end
        task.entity_logs[8].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Group'
          expect(entity_log['class']).to eq 'Cms::Group'
          expect(entity_log['id']).to eq source_group2.id.to_s
          expect(entity_log['deletes']).to include('name', 'contact_email')
        end
      end
    end

    context "unify to existing group" do
      let!(:source_group1) { create(:revision_new_group, order: 10) }
      let!(:source_group2) { create(:revision_new_group, order: 20) }
      let!(:destination_group) { create(:revision_new_group, order: 30) }
      let!(:user1) { create(:cms_user, name: unique_id, email: unique_email, group_ids: [ source_group1.id ]) }
      let!(:user2) { create(:cms_user, name: unique_id, email: unique_email, group_ids: [ source_group2.id ]) }
      let!(:revision) { create(:revision, site_id: site.id) }
      let!(:changeset) do
        create(
          :unify_changeset, revision_id: revision.id, sources: [ source_group1, source_group2 ], destination: destination_group
        )
      end
      let!(:article_node) { create(:article_node_page, cur_site: site) }
      let!(:article_page1) do
        # source_group1 の連絡先
        contact = source_group1.contact_groups.first
        create(
          :article_page, cur_site: site, cur_node: article_node, group_ids: [ source_group1.id, source_group2.id ],
          contact_group_id: source_group1.id, contact_group_contact_id: contact.id, contact_group_relation: "related",
          contact_charge: contact.contact_group_name, contact_tel: contact.contact_tel,
          contact_fax: contact.contact_fax, contact_email: contact.contact_email,
          contact_link_url: contact.contact_link_url, contact_link_name: contact.contact_link_name)
      end
      let!(:article_page2) do
        # source_group2 の連絡先
        contact = source_group2.contact_groups.first
        create(
          :article_page, cur_site: site, cur_node: article_node, group_ids: [ source_group1.id, source_group2.id ],
          contact_group_id: source_group2.id, contact_group_contact_id: contact.id, contact_group_relation: "related",
          contact_charge: contact.contact_group_name, contact_tel: contact.contact_tel,
          contact_fax: contact.contact_fax, contact_email: contact.contact_email,
          contact_link_url: contact.contact_link_url, contact_link_name: contact.contact_link_name)
      end
      let!(:article_page3) do
        # destination_group の連絡先
        contact = destination_group.contact_groups.first
        create(
          :article_page, cur_site: site, cur_node: article_node, group_ids: [ source_group1.id, source_group2.id ],
          contact_group_id: source_group1.id, contact_group_contact_id: contact.id, contact_group_relation: "related",
          contact_charge: contact.contact_group_name, contact_tel: contact.contact_tel,
          contact_fax: contact.contact_fax, contact_email: contact.contact_email,
          contact_link_url: contact.contact_link_url, contact_link_name: contact.contact_link_name)
      end

      it do
        # pre-check
        expect(changeset.destinations).to have(1).items
        changeset.destinations[0].tap do |destination|
          expect(destination[:name]).to eq destination_group.name
          expect(destination[:contact_groups].length).to eq 2
          expect(destination[:contact_groups][0][:_id]).to eq source_group1.contact_groups.first.id.to_s
          expect(destination[:contact_groups][1][:_id]).to eq source_group2.contact_groups.first.id.to_s
        end

        # execute
        job = described_class.bind(site_id: site.id, task_id: task.id, user_id: user1.id)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[統合] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        # check group
        expect { Cms::Group.find(source_group1.id) }.to raise_error Mongoid::Errors::DocumentNotFound
        expect { Cms::Group.find(source_group1.name) }.to raise_error Mongoid::Errors::DocumentNotFound
        expect { Cms::Group.find(source_group2.id) }.to raise_error Mongoid::Errors::DocumentNotFound
        expect { Cms::Group.find(source_group2.name) }.to raise_error Mongoid::Errors::DocumentNotFound
        group_after_unify = Cms::Group.find(destination_group.id).tap do |group_after_unify|
          expect(group_after_unify.id).to eq destination_group.id
          destination0 = changeset.destinations.first
          expect(group_after_unify.name).to eq destination0["name"]

          expect(group_after_unify.contact_groups.count).to eq 2
          group_after_unify.contact_groups[0].tap do |contact_after_unify|
            source_contact0 = source_group1.contact_groups[0]
            expect(contact_after_unify.id).to eq source_contact0.id

            destination_contact = destination0["contact_groups"][0]
            expect(contact_after_unify.name).to eq destination_contact["name"]
            expect(contact_after_unify.main_state).to eq destination_contact["main_state"]
            expect(contact_after_unify.contact_group_name).to eq destination_contact["contact_group_name"]
            expect(contact_after_unify.contact_tel).to eq destination_contact["contact_tel"]
            expect(contact_after_unify.contact_fax).to eq destination_contact["contact_fax"]
            expect(contact_after_unify.contact_email).to eq destination_contact["contact_email"]
            expect(contact_after_unify.contact_link_url).to eq destination_contact["contact_link_url"]
            expect(contact_after_unify.contact_link_name).to eq destination_contact["contact_link_name"]
          end
          group_after_unify.contact_groups[1].tap do |contact_after_unify|
            source_contact0 = source_group2.contact_groups[0]
            expect(contact_after_unify.id).to eq source_contact0.id

            destination_contact = destination0["contact_groups"][1]
            expect(contact_after_unify.name).to eq destination_contact["name"]
            expect(contact_after_unify.main_state).to eq destination_contact["main_state"]
            expect(contact_after_unify.contact_group_name).to eq destination_contact["contact_group_name"]
            expect(contact_after_unify.contact_tel).to eq destination_contact["contact_tel"]
            expect(contact_after_unify.contact_fax).to eq destination_contact["contact_fax"]
            expect(contact_after_unify.contact_email).to eq destination_contact["contact_email"]
            expect(contact_after_unify.contact_link_url).to eq destination_contact["contact_link_url"]
            expect(contact_after_unify.contact_link_name).to eq destination_contact["contact_link_name"]
          end
        end

        # check page
        Cms::Page.find(article_page1.id).tap do |page_after_unify|
          expect(page_after_unify.group_ids).to eq [ group_after_unify.id ]
          expect(page_after_unify.contact_group_id).to eq group_after_unify.id
          contact_after_unify = group_after_unify.contact_groups[0]
          expect(page_after_unify.contact_group_contact_id).to eq contact_after_unify.id
          expect(page_after_unify.contact_group_relation).to eq "related"
          expect(page_after_unify.contact_tel).to eq contact_after_unify.contact_tel
          expect(page_after_unify.contact_fax).to eq contact_after_unify.contact_fax
          expect(page_after_unify.contact_email).to eq contact_after_unify.contact_email
          expect(page_after_unify.contact_link_url).to eq contact_after_unify.contact_link_url
          expect(page_after_unify.contact_link_name).to eq contact_after_unify.contact_link_name
        end
        Cms::Page.find(article_page2.id).tap do |page_after_unify|
          expect(page_after_unify.group_ids).to eq [ group_after_unify.id ]
          expect(page_after_unify.contact_group_id).to eq group_after_unify.id
          contact_after_unify = group_after_unify.contact_groups[1]
          expect(page_after_unify.contact_group_contact_id).to eq contact_after_unify.id
          expect(page_after_unify.contact_group_relation).to eq "related"
          expect(page_after_unify.contact_tel).to eq contact_after_unify.contact_tel
          expect(page_after_unify.contact_fax).to eq contact_after_unify.contact_fax
          expect(page_after_unify.contact_email).to eq contact_after_unify.contact_email
          expect(page_after_unify.contact_link_url).to eq contact_after_unify.contact_link_url
          expect(page_after_unify.contact_link_name).to eq contact_after_unify.contact_link_name
        end
        Cms::Page.find(article_page3.id).tap do |page_after_unify|
          # 組織変更を実行すると destination_group の連絡先が消えるので、ページの連携が切れてしまう。
          # この動作が自明じゃないのがツラいが、このようなケースでは「主へ統合」オプションを設定するものとする。
          expect(page_after_unify.group_ids).to eq [ group_after_unify.id ]
          expect(page_after_unify.contact_group_id).to eq group_after_unify.id
          expect(page_after_unify.contact_group_contact_id).to be_blank
          expect(page_after_unify.contact_group_relation).to eq "related"
          expect(page_after_unify.contact_charge).to eq article_page3.contact_charge
          expect(page_after_unify.contact_tel).to eq article_page3.contact_tel
          expect(page_after_unify.contact_fax).to eq article_page3.contact_fax
          expect(page_after_unify.contact_email).to eq article_page3.contact_email
          expect(page_after_unify.contact_link_url).to eq article_page3.contact_link_url
          expect(page_after_unify.contact_link_name).to eq article_page3.contact_link_name
        end

        user1.reload
        expect(user1.group_ids).to eq [ group_after_unify.id ]
        user2.reload
        expect(user2.group_ids).to eq [ group_after_unify.id ]

        task.reload
        expect(task.state).to eq 'completed'
        expect(task.entity_logs.count).to eq 10
        task.entity_logs[0].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Group'
          expect(entity_log['class']).to eq 'Cms::Group'
          expect(entity_log['id']).to eq destination_group.id.to_s
          expect(entity_log['changes']).to be_present
        end
        task.entity_logs[1].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Site'
          expect(entity_log['class']).to eq 'Cms::Site'
          expect(entity_log['id']).to eq site.id.to_s
          expect(entity_log['changes']).to include('group_ids')
        end
        task.entity_logs[2].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::User'
          expect(entity_log['class']).to eq 'Cms::User'
          expect(entity_log['id']).to eq user1.id.to_s
          expect(entity_log['changes']).to include('group_ids')
        end
        task.entity_logs[3].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::User'
          expect(entity_log['class']).to eq 'Cms::User'
          expect(entity_log['id']).to eq user2.id.to_s
          expect(entity_log['changes']).to include('group_ids')
        end
        task.entity_logs[4].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Node'
          expect(entity_log['class']).to eq 'Article::Node::Page'
          expect(entity_log['id']).to eq article_node.id.to_s
          expect(entity_log['changes']).to include("conditions")
        end
        task.entity_logs[-2].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Group'
          expect(entity_log['id']).to eq source_group1.id.to_s
          expect(entity_log['deletes']).to be_present
        end
        task.entity_logs[-1].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Group'
          expect(entity_log['id']).to eq source_group2.id.to_s
          expect(entity_log['deletes']).to be_present
        end
      end
    end
  end
end
