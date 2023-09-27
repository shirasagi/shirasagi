require 'spec_helper'

describe Chorg::MainRunner, dbscope: :example do
  let!(:root_group) { create(:revision_root_group) }
  let!(:site) { create(:cms_site, group_ids: [ root_group.id ]) }
  let!(:task) { Chorg::Task.create!(name: unique_id, site_id: site.id) }
  let(:job_opts) { { 'newly_created_group_to_site' => 'add' } }

  context "with division" do
    context "with all available attributes" do
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

      let!(:user) { create(:cms_user, name: unique_id, email: unique_email, group_ids: [ source_group.id ]) }

      let!(:revision) { create(:revision, site_id: site.id) }
      let(:destination1_contact) do
        main_contact = source_group.contact_groups.where(main_state: "main").first
        if main_contact
          {
            _id: main_contact.id.to_s, main_state: "main", name: unique_id,
            contact_group_name: "name-#{unique_id}", contact_tel: unique_tel, contact_fax: unique_tel,
            contact_email: unique_email, contact_link_url: "/#{unique_id}/", contact_link_name: "link-#{unique_id}",
          }.with_indifferent_access
        end
      end
      let(:destination2_contact) do
        sub_contact = source_group.contact_groups.ne(main_state: "main").first
        if sub_contact
          {
            _id: sub_contact.id.to_s, main_state: "main", name: unique_id,
            contact_group_name: "name-#{unique_id}", contact_tel: unique_tel, contact_fax: unique_tel,
            contact_email: unique_email, contact_link_url: "/#{unique_id}/", contact_link_name: "link-#{unique_id}",
          }.with_indifferent_access
        end
      end
      let(:destination1) do
        {
          name: "#{root_group.name}/#{unique_id}", order: rand(1..10).to_s,
          ldap_dn: "dc=dc-#{unique_id},dc=city,dc=example,dc=jp",
          contact_groups: [ destination1_contact ]
        }.with_indifferent_access
      end
      let(:destination2) do
        {
          name: "#{root_group.name}/#{unique_id}", order: rand(1..10).to_s,
          ldap_dn: "dc=dc-#{unique_id},dc=city,dc=example,dc=jp",
          contact_groups: [ destination2_contact ]
        }.with_indifferent_access
      end
      let!(:changeset) do
        create(
          :division_changeset, revision_id: revision.id, source: source_group,
          destinations: [ destination1, destination2 ])
      end

      let!(:article_node) { create(:article_node_page, cur_site: site) }
      let!(:article_page1) do
        # source_group の主連絡先
        main_contact = source_group.contact_groups.where(main_state: "main").first

        create(
          :article_page, cur_site: site, cur_node: article_node, group_ids: [ source_group.id ],
          contact_group_id: source_group.id, contact_group_contact_id: main_contact.id, contact_group_relation: "related",
          contact_charge: main_contact.contact_group_name, contact_tel: main_contact.contact_tel,
          contact_fax: main_contact.contact_fax, contact_email: main_contact.contact_email,
          contact_link_url: main_contact.contact_link_url, contact_link_name: main_contact.contact_link_name)
      end
      let!(:article_page2) do
        # source_group のサブ連絡先
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
        job = described_class.bind(site_id: site.id, task_id: task.id, user_id: user.id)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[分割] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        # check group
        group_after_division1 = Cms::Group.find(source_group.id).tap do |group_after_division|
          expect(group_after_division.name).not_to eq source_group.name
          expect(group_after_division.name).to eq destination1[:name]
          expect(group_after_division.order).to eq destination1[:order].to_i
          expect(group_after_division.ldap_dn).to eq destination1[:ldap_dn]
          expect(group_after_division.contact_groups.count).to eq 1
          group_after_division.contact_groups.first.tap do |contact_after_division|
            expect(contact_after_division.id.to_s).to eq destination1_contact[:_id]
            expect(contact_after_division.name).to eq destination1_contact[:name]
            expect(contact_after_division.main_state).to eq destination1_contact[:main_state]
            expect(contact_after_division.contact_group_name).to eq destination1_contact[:contact_group_name]
            expect(contact_after_division.contact_tel).to eq destination1_contact[:contact_tel]
            expect(contact_after_division.contact_fax).to eq destination1_contact[:contact_fax]
            expect(contact_after_division.contact_email).to eq destination1_contact[:contact_email]
            expect(contact_after_division.contact_link_url).to eq destination1_contact[:contact_link_url]
            expect(contact_after_division.contact_link_name).to eq destination1_contact[:contact_link_name]
          end
        end
        group_after_division2 = Cms::Group.find_by(name: destination2[:name]).tap do |group_after_division|
          expect(group_after_division.name).to eq destination2[:name]
          expect(group_after_division.order).to eq destination2[:order].to_i
          expect(group_after_division.ldap_dn).to eq destination2[:ldap_dn]
          expect(group_after_division.contact_groups.count).to eq 1
          group_after_division.contact_groups.first.tap do |contact_after_division|
            expect(contact_after_division.id.to_s).to eq destination2_contact[:_id]
            expect(contact_after_division.name).to eq destination2_contact[:name]
            expect(contact_after_division.main_state).to eq destination2_contact[:main_state]
            expect(contact_after_division.contact_group_name).to eq destination2_contact[:contact_group_name]
            expect(contact_after_division.contact_tel).to eq destination2_contact[:contact_tel]
            expect(contact_after_division.contact_fax).to eq destination2_contact[:contact_fax]
            expect(contact_after_division.contact_email).to eq destination2_contact[:contact_email]
            expect(contact_after_division.contact_link_url).to eq destination2_contact[:contact_link_url]
            expect(contact_after_division.contact_link_name).to eq destination2_contact[:contact_link_name]
          end
        end

        # check page
        Cms::Page.find(article_page1.id).tap do |page_after_division|
          expect(page_after_division.group_ids).to eq [ group_after_division1.id, group_after_division2.id ]
          expect(page_after_division.contact_group_id).to eq group_after_division1.id
          contact_after_division = group_after_division1.contact_groups.first
          expect(page_after_division.contact_group_contact_id).to eq contact_after_division.id
          expect(page_after_division.contact_group_relation).to eq "related"
          expect(page_after_division.contact_tel).to eq contact_after_division.contact_tel
          expect(page_after_division.contact_fax).to eq contact_after_division.contact_fax
          expect(page_after_division.contact_email).to eq contact_after_division.contact_email
          expect(page_after_division.contact_link_url).to eq contact_after_division.contact_link_url
          expect(page_after_division.contact_link_name).to eq contact_after_division.contact_link_name
        end
        Cms::Page.find(article_page2.id).tap do |page_after_division|
          expect(page_after_division.group_ids).to eq [ group_after_division1.id, group_after_division2.id ]
          expect(page_after_division.contact_group_id).to eq group_after_division2.id
          contact_after_division = group_after_division2.contact_groups[0]
          expect(page_after_division.contact_group_contact_id).to eq contact_after_division.id
          expect(page_after_division.contact_group_relation).to eq "related"
          expect(page_after_division.contact_tel).to eq contact_after_division.contact_tel
          expect(page_after_division.contact_fax).to eq contact_after_division.contact_fax
          expect(page_after_division.contact_email).to eq contact_after_division.contact_email
          expect(page_after_division.contact_link_url).to eq contact_after_division.contact_link_url
          expect(page_after_division.contact_link_name).to eq contact_after_division.contact_link_name
        end

        user.reload
        expect(user.group_ids).to eq [ group_after_division1.id ]

        task.reload
        expect(task.state).to eq 'completed'
        expect(task.entity_logs.count).to eq 9
        task.entity_logs[0].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Group'
          expect(entity_log['class']).to eq 'Cms::Group'
          expect(entity_log['id']).to eq group_after_division1.id.to_s
          expect(entity_log['changes']).to be_present
        end
        task.entity_logs[1].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Group'
          expect(entity_log['class']).to eq 'Cms::Group'
          expect(entity_log['id']).to be_blank
          expect(entity_log['changes']).to be_blank
          expect(entity_log['creates']).to be_present
        end
        task.entity_logs[2].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Site'
          expect(entity_log['class']).to eq 'Cms::Site'
          expect(entity_log['id']).to eq site.id.to_s
          expect(entity_log['changes']).to include('group_ids')
        end
        task.entity_logs[3].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Site'
          expect(entity_log['class']).to eq 'Cms::Site'
          expect(entity_log['id']).to eq site.id.to_s
          expect(entity_log['changes']).to include('group_ids')
        end
        task.entity_logs[4].tap do |entity_log|
          expect(entity_log['model']).to eq 'Article::Page'
          expect(entity_log['class']).to eq 'Article::Page'
          expect(entity_log['id']).to eq article_page1.id.to_s
          expect(entity_log['changes']).to include(
            "contact_charge", "contact_tel", "contact_fax", "contact_email", "contact_link_name", "contact_link_url")
        end
        task.entity_logs[5].tap do |entity_log|
          expect(entity_log['model']).to eq 'Article::Page'
          expect(entity_log['class']).to eq 'Article::Page'
          expect(entity_log['id']).to eq article_page2.id.to_s
          expect(entity_log['changes']).to include(
            "contact_charge", "contact_tel", "contact_fax", "contact_email", "contact_link_name", "contact_link_url")
        end
        task.entity_logs[6].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Node'
          expect(entity_log['class']).to eq 'Article::Node::Page'
          expect(entity_log['id']).to eq article_node.id.to_s
          expect(entity_log['changes']).to include('conditions')
        end
        task.entity_logs[7].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Page'
          expect(entity_log['class']).to eq 'Article::Page'
          expect(entity_log['id']).to eq article_page1.id.to_s
          expect(entity_log['changes']).to include("group_ids")
        end
        task.entity_logs[8].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Page'
          expect(entity_log['class']).to eq 'Article::Page'
          expect(entity_log['id']).to eq article_page2.id.to_s
          expect(entity_log['changes']).to include("group_ids")
        end
      end
    end

    context "divide from existing group to existing group #1" do
      let!(:group1) do
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

      let!(:user) { create(:cms_user, name: unique_id, email: unique_email, group_ids: [ group1.id ]) }

      let!(:revision) { create(:revision, site_id: site.id) }
      let(:destination1_contact) do
        main_contact = group1.contact_groups.where(main_state: "main").first
        if main_contact
          {
            _id: main_contact.id.to_s, main_state: "main", name: main_contact.name,
            contact_group_name: main_contact.contact_group_name, contact_tel: main_contact.contact_tel,
            contact_fax: main_contact.contact_fax, contact_email: main_contact.contact_email,
            contact_link_url: main_contact.contact_link_url, contact_link_name: main_contact.contact_link_name,
          }.with_indifferent_access
        end
      end
      let(:destination2_contact) do
        sub_contact = group1.contact_groups.ne(main_state: "main").first
        if sub_contact
          {
            _id: sub_contact.id.to_s, main_state: "main", name: sub_contact.name,
            contact_group_name: sub_contact.contact_group_name, contact_tel: sub_contact.contact_tel,
            contact_fax: sub_contact.contact_fax, contact_email: sub_contact.contact_email,
            contact_link_url: sub_contact.contact_link_url, contact_link_name: sub_contact.contact_link_name,
          }.with_indifferent_access
        end
      end
      let(:destination1) do
        # group1 へ分割する
        {
          name: group1.name, order: group1.order.to_s, ldap_dn: group1.ldap_dn, contact_groups: [ destination1_contact ]
        }.with_indifferent_access
      end
      let(:destination2) do
        # 新しいグループへ分割する
        {
          name: "#{root_group.name}/#{unique_id}", order: rand(1..10).to_s,
          ldap_dn: "dc=dc-#{unique_id},dc=city,dc=example,dc=jp",
          contact_groups: [ destination2_contact ]
        }.with_indifferent_access
      end
      let!(:changeset) do
        create(:division_changeset, revision_id: revision.id, source: group1, destinations: [ destination1, destination2 ])
      end

      let!(:article_node) { create(:article_node_page, cur_site: site) }
      let!(:article_page1) do
        # group1 の主連絡先
        main_contact = group1.contact_groups.where(main_state: "main").first

        create(
          :article_page, cur_site: site, cur_node: article_node, group_ids: [ group1.id ],
          contact_group_id: group1.id, contact_group_contact_id: main_contact.id, contact_group_relation: "related",
          contact_charge: main_contact.contact_group_name, contact_tel: main_contact.contact_tel,
          contact_fax: main_contact.contact_fax, contact_email: main_contact.contact_email,
          contact_link_url: main_contact.contact_link_url, contact_link_name: main_contact.contact_link_name)
      end
      let!(:article_page2) do
        # group1 のサブ連絡先
        sub_contact = group1.contact_groups.ne(main_state: "main").first

        create(
          :article_page, cur_site: site, cur_node: article_node, group_ids: [ group1.id ],
          contact_group_id: group1.id, contact_group_contact_id: sub_contact.id, contact_group_relation: "related",
          contact_charge: sub_contact.contact_group_name, contact_tel: sub_contact.contact_tel,
          contact_fax: sub_contact.contact_fax, contact_email: sub_contact.contact_email,
          contact_link_url: sub_contact.contact_link_url, contact_link_name: sub_contact.contact_link_name)
      end

      it do
        # execute
        job = described_class.bind(site_id: site.id, task_id: task.id, user_id: user.id)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[分割] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        # check group
        group_after_division1 = Cms::Group.find(group1.id).tap do |group_after_division|
          expect(group_after_division.name).to eq group1.name
          expect(group_after_division.order).to eq group1.order
          expect(group_after_division.ldap_dn).to eq group1.ldap_dn
          expect(group_after_division.contact_groups.count).to eq 1
          group_after_division.contact_groups.first.tap do |contact_after_division|
            expect(contact_after_division.id.to_s).to eq destination1_contact[:_id]
            expect(contact_after_division.name).to eq destination1_contact[:name]
            expect(contact_after_division.main_state).to eq destination1_contact[:main_state]
            expect(contact_after_division.contact_group_name).to eq destination1_contact[:contact_group_name]
            expect(contact_after_division.contact_tel).to eq destination1_contact[:contact_tel]
            expect(contact_after_division.contact_fax).to eq destination1_contact[:contact_fax]
            expect(contact_after_division.contact_email).to eq destination1_contact[:contact_email]
            expect(contact_after_division.contact_link_url).to eq destination1_contact[:contact_link_url]
            expect(contact_after_division.contact_link_name).to eq destination1_contact[:contact_link_name]
          end
        end
        group_after_division2 = Cms::Group.find_by(name: destination2[:name]).tap do |group_after_division|
          expect(group_after_division.name).to eq destination2[:name]
          expect(group_after_division.order).to eq destination2[:order].to_i
          expect(group_after_division.ldap_dn).to eq destination2[:ldap_dn]
          expect(group_after_division.contact_groups.count).to eq 1
          group_after_division.contact_groups.first.tap do |contact_after_division|
            expect(contact_after_division.id.to_s).to eq destination2_contact[:_id]
            expect(contact_after_division.name).to eq destination2_contact[:name]
            expect(contact_after_division.main_state).to eq destination2_contact[:main_state]
            expect(contact_after_division.contact_group_name).to eq destination2_contact[:contact_group_name]
            expect(contact_after_division.contact_tel).to eq destination2_contact[:contact_tel]
            expect(contact_after_division.contact_fax).to eq destination2_contact[:contact_fax]
            expect(contact_after_division.contact_email).to eq destination2_contact[:contact_email]
            expect(contact_after_division.contact_link_url).to eq destination2_contact[:contact_link_url]
            expect(contact_after_division.contact_link_name).to eq destination2_contact[:contact_link_name]
          end
        end

        # check page
        Cms::Page.find(article_page1.id).tap do |page_after_division|
          expect(page_after_division.group_ids).to eq [ group_after_division1.id, group_after_division2.id ]
          expect(page_after_division.contact_group_id).to eq group_after_division1.id
          contact_after_division = group_after_division1.contact_groups[0]
          expect(page_after_division.contact_group_contact_id).to eq contact_after_division.id
          expect(page_after_division.contact_group_relation).to eq "related"
          expect(page_after_division.contact_tel).to eq contact_after_division.contact_tel
          expect(page_after_division.contact_fax).to eq contact_after_division.contact_fax
          expect(page_after_division.contact_email).to eq contact_after_division.contact_email
          expect(page_after_division.contact_link_url).to eq contact_after_division.contact_link_url
          expect(page_after_division.contact_link_name).to eq contact_after_division.contact_link_name
        end
        Cms::Page.find(article_page2.id).tap do |page_after_division|
          expect(page_after_division.group_ids).to eq [ group_after_division1.id, group_after_division2.id ]
          expect(page_after_division.contact_group_id).to eq group_after_division2.id
          contact_after_division = group_after_division2.contact_groups[0]
          expect(page_after_division.contact_group_contact_id).to eq contact_after_division.id
          expect(page_after_division.contact_group_relation).to eq "related"
          expect(page_after_division.contact_tel).to eq contact_after_division.contact_tel
          expect(page_after_division.contact_fax).to eq contact_after_division.contact_fax
          expect(page_after_division.contact_email).to eq contact_after_division.contact_email
          expect(page_after_division.contact_link_url).to eq contact_after_division.contact_link_url
          expect(page_after_division.contact_link_name).to eq contact_after_division.contact_link_name
        end

        user.reload
        expect(user.group_ids).to eq [ group_after_division1.id ]

        task.reload
        expect(task.state).to eq 'completed'
        expect(task.entity_logs.count).to eq 9
        task.entity_logs[0].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Group'
          expect(entity_log['class']).to eq 'Cms::Group'
          expect(entity_log['id']).to eq group1.id.to_s
          expect(entity_log['changes']).to be_empty
        end
        task.entity_logs[1].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Group'
          expect(entity_log['class']).to eq 'Cms::Group'
          expect(entity_log['creates']).to be_present
        end
        task.entity_logs[2].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Site'
          expect(entity_log['id']).to eq site.id.to_s
          expect(entity_log['changes']).to include('group_ids')
        end
        task.entity_logs[3].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Site'
          expect(entity_log['class']).to eq 'Cms::Site'
          expect(entity_log['id']).to eq site.id.to_s
          expect(entity_log['changes']).to include('group_ids')
        end
        task.entity_logs[4].tap do |entity_log|
          expect(entity_log['model']).to eq 'Article::Page'
          expect(entity_log['class']).to eq 'Article::Page'
          expect(entity_log['id']).to eq article_page1.id.to_s
          expect(entity_log['changes']).to be_present
        end
        task.entity_logs[5].tap do |entity_log|
          expect(entity_log['model']).to eq 'Article::Page'
          expect(entity_log['class']).to eq 'Article::Page'
          expect(entity_log['id']).to eq article_page2.id.to_s
          expect(entity_log['changes']).to be_present
        end
        task.entity_logs[6].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Node'
          expect(entity_log['class']).to eq 'Article::Node::Page'
          expect(entity_log['id']).to eq article_node.id.to_s
          expect(entity_log['changes']).to include("conditions")
        end
        task.entity_logs[7].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Page'
          expect(entity_log['class']).to eq 'Article::Page'
          expect(entity_log['id']).to eq article_page1.id.to_s
          expect(entity_log['changes']).to include("group_ids")
        end
        task.entity_logs[8].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Page'
          expect(entity_log['class']).to eq 'Article::Page'
          expect(entity_log['id']).to eq article_page2.id.to_s
          expect(entity_log['changes']).to include("group_ids")
        end
      end
    end

    context "divide from existing group to existing group #2" do
      let!(:group1) do
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
      let!(:group2) do
        create(
          :cms_group, name: "#{root_group.name}/#{unique_id}", order: 20,
          contact_groups: [
            {
              main_state: "main", name: "name-#{unique_id}", contact_group_name: "contact_group_name-#{unique_id}",
              contact_tel: unique_tel, contact_fax: unique_tel, contact_email: unique_email,
              contact_link_url: "/#{unique_id}", contact_link_name: "link_name-#{unique_id}",
            }
          ]
        )
      end

      let!(:user) { create(:cms_user, name: unique_id, email: unique_email, group_ids: [ group1.id ]) }

      let!(:revision) { create(:revision, site_id: site.id) }
      let(:destination1_contact) do
        main_contact = group1.contact_groups.where(main_state: "main").first
        if main_contact
          {
            _id: main_contact.id.to_s, main_state: "main", name: main_contact.name,
            contact_group_name: main_contact.contact_group_name, contact_tel: main_contact.contact_tel,
            contact_fax: main_contact.contact_fax, contact_email: main_contact.contact_email,
            contact_link_url: main_contact.contact_link_url, contact_link_name: main_contact.contact_link_name,
          }.with_indifferent_access
        end
      end
      let(:destination2_contact) do
        sub_contact = group1.contact_groups.ne(main_state: "main").first
        if sub_contact
          {
            _id: sub_contact.id.to_s, main_state: "main", name: sub_contact.name,
            contact_group_name: sub_contact.contact_group_name, contact_tel: sub_contact.contact_tel,
            contact_fax: sub_contact.contact_fax, contact_email: sub_contact.contact_email,
            contact_link_url: sub_contact.contact_link_url, contact_link_name: sub_contact.contact_link_name,
          }.with_indifferent_access
        end
      end
      let(:destination1) do
        # 新しいグループへ分割する
        {
          name: "#{root_group.name}/#{unique_id}", order: rand(1..10).to_s,
          ldap_dn: "dc=dc-#{unique_id},dc=city,dc=example,dc=jp",
          contact_groups: [ destination1_contact ]
        }.with_indifferent_access
      end
      let(:destination2) do
        # group2 へ分割する
        {
          name: group2.name, order: group2.order.to_s, ldap_dn: group2.ldap_dn, contact_groups: [ destination2_contact ]
        }.with_indifferent_access
      end
      let!(:changeset) do
        create(:division_changeset, revision_id: revision.id, source: group1, destinations: [ destination1, destination2 ])
      end

      let!(:article_node) { create(:article_node_page, cur_site: site) }
      let!(:article_page1) do
        # group1 の主連絡先
        main_contact = group1.contact_groups.where(main_state: "main").first

        create(
          :article_page, cur_site: site, cur_node: article_node, group_ids: [ group1.id ],
          contact_group_id: group1.id, contact_group_contact_id: main_contact.id, contact_group_relation: "related",
          contact_charge: main_contact.contact_group_name, contact_tel: main_contact.contact_tel,
          contact_fax: main_contact.contact_fax, contact_email: main_contact.contact_email,
          contact_link_url: main_contact.contact_link_url, contact_link_name: main_contact.contact_link_name)
      end
      let!(:article_page2) do
        # group1 のサブ連絡先
        sub_contact = group1.contact_groups.ne(main_state: "main").first

        create(
          :article_page, cur_site: site, cur_node: article_node, group_ids: [ group1.id ],
          contact_group_id: group1.id, contact_group_contact_id: sub_contact.id, contact_group_relation: "related",
          contact_charge: sub_contact.contact_group_name, contact_tel: sub_contact.contact_tel,
          contact_fax: sub_contact.contact_fax, contact_email: sub_contact.contact_email,
          contact_link_url: sub_contact.contact_link_url, contact_link_name: sub_contact.contact_link_name)
      end
      let!(:article_page3) do
        # group2 の主連絡先
        main_contact = group2.contact_groups.where(main_state: "main").first

        create(
          :article_page, cur_site: site, cur_node: article_node, group_ids: [ group2.id ],
          contact_group_id: group2.id, contact_group_contact_id: main_contact.id, contact_group_relation: "related",
          contact_charge: main_contact.contact_group_name, contact_tel: main_contact.contact_tel,
          contact_fax: main_contact.contact_fax, contact_email: main_contact.contact_email,
          contact_link_url: main_contact.contact_link_url, contact_link_name: main_contact.contact_link_name)
      end

      it do
        # execute
        job = described_class.bind(site_id: site.id, task_id: task.id, user_id: user.id)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[分割] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        # check group
        group_after_division1 = Cms::Group.find_by(name: destination1[:name]).tap do |group_after_division|
          # なるべく新しいグループは作成しないという方針により、group1 が流用されているはず
          expect(group_after_division.id).to eq group1.id

          expect(group_after_division.name).to eq destination1[:name]
          expect(group_after_division.order).to eq destination1[:order].to_i
          expect(group_after_division.ldap_dn).to eq destination1[:ldap_dn]
          expect(group_after_division.contact_groups.count).to eq 1
          group_after_division.contact_groups.first.tap do |contact_after_division|
            expect(contact_after_division.id.to_s).to eq destination1_contact[:_id]
            expect(contact_after_division.name).to eq destination1_contact[:name]
            expect(contact_after_division.main_state).to eq destination1_contact[:main_state]
            expect(contact_after_division.contact_group_name).to eq destination1_contact[:contact_group_name]
            expect(contact_after_division.contact_tel).to eq destination1_contact[:contact_tel]
            expect(contact_after_division.contact_fax).to eq destination1_contact[:contact_fax]
            expect(contact_after_division.contact_email).to eq destination1_contact[:contact_email]
            expect(contact_after_division.contact_link_url).to eq destination1_contact[:contact_link_url]
            expect(contact_after_division.contact_link_name).to eq destination1_contact[:contact_link_name]
          end
        end
        group_after_division2 = Cms::Group.find_by(name: destination2[:name]).tap do |group_after_division|
          # destination2 は分割結果を group2 へ設定するよう構成されている
          expect(group_after_division.id).to eq group2.id

          expect(group_after_division.name).to eq destination2[:name]
          expect(group_after_division.order).to eq destination2[:order].to_i
          expect(group_after_division.ldap_dn).to eq destination2[:ldap_dn]
          expect(group_after_division.contact_groups.count).to eq 1
          group_after_division.contact_groups.first.tap do |contact_after_division|
            expect(contact_after_division.id.to_s).to eq destination2_contact[:_id]
            expect(contact_after_division.name).to eq destination2_contact[:name]
            expect(contact_after_division.main_state).to eq destination2_contact[:main_state]
            expect(contact_after_division.contact_group_name).to eq destination2_contact[:contact_group_name]
            expect(contact_after_division.contact_tel).to eq destination2_contact[:contact_tel]
            expect(contact_after_division.contact_fax).to eq destination2_contact[:contact_fax]
            expect(contact_after_division.contact_email).to eq destination2_contact[:contact_email]
            expect(contact_after_division.contact_link_url).to eq destination2_contact[:contact_link_url]
            expect(contact_after_division.contact_link_name).to eq destination2_contact[:contact_link_name]
          end
        end

        # check page
        Cms::Page.find(article_page1.id).tap do |page_after_division|
          expect(page_after_division.group_ids).to eq [ group_after_division1.id, group_after_division2.id ]
          expect(page_after_division.contact_group_id).to eq group_after_division1.id
          contact_after_division = group_after_division1.contact_groups[0]
          expect(page_after_division.contact_group_contact_id).to eq contact_after_division.id
          expect(page_after_division.contact_group_relation).to eq "related"
          expect(page_after_division.contact_tel).to eq contact_after_division.contact_tel
          expect(page_after_division.contact_fax).to eq contact_after_division.contact_fax
          expect(page_after_division.contact_email).to eq contact_after_division.contact_email
          expect(page_after_division.contact_link_url).to eq contact_after_division.contact_link_url
          expect(page_after_division.contact_link_name).to eq contact_after_division.contact_link_name
        end
        Cms::Page.find(article_page2.id).tap do |page_after_division|
          expect(page_after_division.group_ids).to eq [ group_after_division1.id, group_after_division2.id ]
          expect(page_after_division.contact_group_id).to eq group_after_division2.id
          contact_after_division = group_after_division2.contact_groups[0]
          expect(page_after_division.contact_group_contact_id).to eq contact_after_division.id
          expect(page_after_division.contact_group_relation).to eq "related"
          expect(page_after_division.contact_tel).to eq contact_after_division.contact_tel
          expect(page_after_division.contact_fax).to eq contact_after_division.contact_fax
          expect(page_after_division.contact_email).to eq contact_after_division.contact_email
          expect(page_after_division.contact_link_url).to eq contact_after_division.contact_link_url
          expect(page_after_division.contact_link_name).to eq contact_after_division.contact_link_name
        end
        Cms::Page.find(article_page3.id).tap do |page_after_division|
          # 組織変更を実行すると group2 の連絡先が全て削除され、新しい連絡先に置き換わるので、ページの連携が切れてしまう。
          # この動作が自明じゃないのがツラいが、このようなケースでは「主へ統合」オプションを設定するものとする。
          expect(page_after_division.group_ids).to eq [ group_after_division2.id ]
          expect(page_after_division.contact_group_id).to eq group_after_division2.id
          contact_after_division = group_after_division2.contact_groups[0]
          expect(page_after_division.contact_group_contact_id).to be_blank
          expect(page_after_division.contact_group_relation).to eq "related"
          expect(page_after_division.contact_tel).to eq article_page3.contact_tel
          expect(page_after_division.contact_fax).to eq article_page3.contact_fax
          expect(page_after_division.contact_email).to eq article_page3.contact_email
          expect(page_after_division.contact_link_url).to eq article_page3.contact_link_url
          expect(page_after_division.contact_link_name).to eq article_page3.contact_link_name
        end

        user.reload
        expect(user.group_ids).to eq [ group_after_division1.id ]

        task.reload
        expect(task.state).to eq 'completed'
        expect(task.entity_logs.count).to eq 10
        task.entity_logs[0].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Group'
          expect(entity_log['class']).to eq 'Cms::Group'
          expect(entity_log['id']).to eq group1.id.to_s
          expect(entity_log['changes']).to be_present
        end
        task.entity_logs[1].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Group'
          expect(entity_log['class']).to eq 'Cms::Group'
          expect(entity_log['id']).to eq group2.id.to_s
          expect(entity_log['changes']).to be_present
        end
        task.entity_logs[2].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Site'
          expect(entity_log['id']).to eq site.id.to_s
          expect(entity_log['changes']).to include('group_ids')
        end
        task.entity_logs[3].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Site'
          expect(entity_log['class']).to eq 'Cms::Site'
          expect(entity_log['id']).to eq site.id.to_s
          expect(entity_log['changes']).to include('group_ids')
        end
        task.entity_logs[4].tap do |entity_log|
          expect(entity_log['model']).to eq 'Article::Page'
          expect(entity_log['class']).to eq 'Article::Page'
          expect(entity_log['id']).to eq article_page1.id.to_s
          expect(entity_log['changes']).to be_present
        end
        task.entity_logs[5].tap do |entity_log|
          expect(entity_log['model']).to eq 'Article::Page'
          expect(entity_log['class']).to eq 'Article::Page'
          expect(entity_log['id']).to eq article_page2.id.to_s
          expect(entity_log['changes']).to be_present
        end
        task.entity_logs[6].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Node'
          expect(entity_log['class']).to eq 'Article::Node::Page'
          expect(entity_log['id']).to eq article_node.id.to_s
          expect(entity_log['changes']).to include("conditions")
        end
        task.entity_logs[7].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Page'
          expect(entity_log['class']).to eq 'Article::Page'
          expect(entity_log['id']).to eq article_page1.id.to_s
          expect(entity_log['changes']).to include("group_ids")
        end
        task.entity_logs[8].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Page'
          expect(entity_log['class']).to eq 'Article::Page'
          expect(entity_log['id']).to eq article_page2.id.to_s
          expect(entity_log['changes']).to include("group_ids")
        end
        task.entity_logs[9].tap do |entity_log|
          expect(entity_log['model']).to eq 'Cms::Page'
          expect(entity_log['class']).to eq 'Article::Page'
          expect(entity_log['id']).to eq article_page3.id.to_s
          expect(entity_log['changes']).to include("contact_group_contact_id")
        end
      end
    end
  end
end
