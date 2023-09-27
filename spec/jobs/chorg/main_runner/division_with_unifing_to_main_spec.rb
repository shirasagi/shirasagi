require 'spec_helper'

describe Chorg::MainRunner, dbscope: :example do
  let!(:root_group) { create(:revision_root_group) }
  let!(:site) { create(:cms_site, group_ids: [root_group.id]) }
  let!(:task) { Chorg::Task.create!(name: unique_id, site_id: site.id) }
  let(:job_opts) { { 'newly_created_group_to_site' => 'add' } }

  context "division with unifing contacts to main #1: 理想的に分割後が設定されたケース" do
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
          },
          {
            main_state: nil, name: "name-#{unique_id}", contact_group_name: "contact_group_name-#{unique_id}",
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
    let(:sub_contacts) { source_group.contact_groups.ne(main_state: "main").to_a }

    let!(:revision) { create(:revision, site_id: site.id) }
    let(:destination1_contact1) do
      # 分割先1は「主へ統合」を有効化
      main_contact = source_group.contact_groups.where(main_state: "main").first
      {
        _id: main_contact.id.to_s, main_state: "main", name: unique_id, unifies_to_main: "enabled",
        contact_group_name: "name-#{unique_id}", contact_tel: unique_tel, contact_fax: unique_tel,
        contact_email: unique_email, contact_link_url: "/#{unique_id}/", contact_link_name: "link-#{unique_id}",
      }.with_indifferent_access
    end
    let(:destination1_contact2) do
      # 分割先1は「主へ統合」を有効化
      sub_contact = sub_contacts[0]
      {
        _id: sub_contact.id.to_s, main_state: nil, name: unique_id, unifies_to_main: "enabled",
        contact_group_name: "name-#{unique_id}", contact_tel: unique_tel, contact_fax: unique_tel,
        contact_email: unique_email, contact_link_url: "/#{unique_id}/", contact_link_name: "link-#{unique_id}",
      }.with_indifferent_access
    end
    let(:destination2_contact1) do
      # 分割先2は「主へ統合」を無効化
      sub_contact = sub_contacts[1]
      {
        _id: sub_contact.id.to_s, main_state: "main", name: unique_id, unifies_to_main: nil,
        contact_group_name: "name-#{unique_id}", contact_tel: unique_tel, contact_fax: unique_tel,
        contact_email: unique_email, contact_link_url: "/#{unique_id}/", contact_link_name: "link-#{unique_id}",
      }.with_indifferent_access
    end
    let(:destination2_contact2) do
      # 分割先2は「主へ統合」を無効化
      sub_contact = sub_contacts[2]
      {
        _id: sub_contact.id.to_s, main_state: nil, name: unique_id, unifies_to_main: nil,
        contact_group_name: "name-#{unique_id}", contact_tel: unique_tel, contact_fax: unique_tel,
        contact_email: unique_email, contact_link_url: "/#{unique_id}/", contact_link_name: "link-#{unique_id}",
      }.with_indifferent_access
    end
    let(:destination1) do
      {
        name: "#{root_group.name}/#{unique_id}", order: rand(1..10).to_s,
        ldap_dn: "dc=dc-#{unique_id},dc=city,dc=example,dc=jp",
        contact_groups: [ destination1_contact1, destination1_contact2 ]
      }.with_indifferent_access
    end
    let(:destination2) do
      {
        name: "#{root_group.name}/#{unique_id}", order: rand(1..10).to_s,
        ldap_dn: "dc=dc-#{unique_id},dc=city,dc=example,dc=jp",
        contact_groups: [ destination2_contact1, destination2_contact2 ]
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
      # source_group のサブ連絡先 #1
      sub_contact = sub_contacts[0]

      create(
        :article_page, cur_site: site, cur_node: article_node, group_ids: [ source_group.id ],
        contact_group_id: source_group.id, contact_group_contact_id: sub_contact.id, contact_group_relation: "related",
        contact_charge: sub_contact.contact_group_name, contact_tel: sub_contact.contact_tel,
        contact_fax: sub_contact.contact_fax, contact_email: sub_contact.contact_email,
        contact_link_url: sub_contact.contact_link_url, contact_link_name: sub_contact.contact_link_name)
    end
    let!(:article_page3) do
      # source_group のサブ連絡先 #2
      sub_contact = sub_contacts[1]

      create(
        :article_page, cur_site: site, cur_node: article_node, group_ids: [ source_group.id ],
        contact_group_id: source_group.id, contact_group_contact_id: sub_contact.id, contact_group_relation: "related",
        contact_charge: sub_contact.contact_group_name, contact_tel: sub_contact.contact_tel,
        contact_fax: sub_contact.contact_fax, contact_email: sub_contact.contact_email,
        contact_link_url: sub_contact.contact_link_url, contact_link_name: sub_contact.contact_link_name)
    end
    let!(:article_page4) do
      # source_group のサブ連絡先 #3
      sub_contact = sub_contacts[2]

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
      expect { job.perform_now(revision.name, job_opts) }.to output(include("[分割] 成功: 1, 失敗: 0\n")).to_stdout

      # check for job was succeeded
      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      group_after_division1 = Cms::Group.find(source_group.id).tap do |group_after_division|
        expect(group_after_division.contact_groups.count).to eq 2
        group_after_division.contact_groups.where(main_state: "main").first.tap do |contact|
          expect(contact.main_state).to eq destination1_contact1[:main_state]
          expect(contact.name).to eq destination1_contact1[:name]
          expect(contact.contact_group_name).to eq destination1_contact1[:contact_group_name]
          expect(contact.contact_tel).to eq destination1_contact1[:contact_tel]
          expect(contact.contact_fax).to eq destination1_contact1[:contact_fax]
          expect(contact.contact_email).to eq destination1_contact1[:contact_email]
          expect(contact.contact_link_url).to eq destination1_contact1[:contact_link_url]
          expect(contact.contact_link_name).to eq destination1_contact1[:contact_link_name]
        end
        group_after_division.contact_groups.ne(main_state: "main").first.tap do |contact|
          expect(contact.main_state).to eq destination1_contact2[:main_state]
          expect(contact.name).to eq destination1_contact2[:name]
          expect(contact.contact_group_name).to eq destination1_contact2[:contact_group_name]
          expect(contact.contact_tel).to eq destination1_contact2[:contact_tel]
          expect(contact.contact_fax).to eq destination1_contact2[:contact_fax]
          expect(contact.contact_email).to eq destination1_contact2[:contact_email]
          expect(contact.contact_link_url).to eq destination1_contact2[:contact_link_url]
          expect(contact.contact_link_name).to eq destination1_contact2[:contact_link_name]
        end
      end
      group_after_division2 = Cms::Group.find_by(name: destination2[:name]).tap do |group_after_division|
        expect(group_after_division.contact_groups.count).to eq 2
        group_after_division.contact_groups.where(main_state: "main").first.tap do |contact|
          expect(contact.main_state).to eq destination2_contact1[:main_state]
          expect(contact.name).to eq destination2_contact1[:name]
          expect(contact.contact_group_name).to eq destination2_contact1[:contact_group_name]
          expect(contact.contact_tel).to eq destination2_contact1[:contact_tel]
          expect(contact.contact_fax).to eq destination2_contact1[:contact_fax]
          expect(contact.contact_email).to eq destination2_contact1[:contact_email]
          expect(contact.contact_link_url).to eq destination2_contact1[:contact_link_url]
          expect(contact.contact_link_name).to eq destination2_contact1[:contact_link_name]
        end
        group_after_division.contact_groups.ne(main_state: "main").first.tap do |contact|
          expect(contact.main_state).to eq destination2_contact2[:main_state]
          expect(contact.name).to eq destination2_contact2[:name]
          expect(contact.contact_group_name).to eq destination2_contact2[:contact_group_name]
          expect(contact.contact_tel).to eq destination2_contact2[:contact_tel]
          expect(contact.contact_fax).to eq destination2_contact2[:contact_fax]
          expect(contact.contact_email).to eq destination2_contact2[:contact_email]
          expect(contact.contact_link_url).to eq destination2_contact2[:contact_link_url]
          expect(contact.contact_link_name).to eq destination2_contact2[:contact_link_name]
        end
      end
      group_after_division1_main_contact = group_after_division1.contact_groups.where(main_state: "main").first
      group_after_division2_main_contact = group_after_division2.contact_groups.where(main_state: "main").first
      group_after_division2_sub_contact = group_after_division2.contact_groups.ne(main_state: "main").first

      Article::Page.find(article_page1.id).tap do |page|
        expect(page.contact_group_id).to eq group_after_division1.id
        expect(page.contact_group_contact_id).to eq group_after_division1_main_contact.id
        expect(page.contact_group_relation).to eq "related"
        expect(page.contact_charge).to eq group_after_division1_main_contact.contact_group_name
        expect(page.contact_tel).to eq group_after_division1_main_contact.contact_tel
        expect(page.contact_fax).to eq group_after_division1_main_contact.contact_fax
        expect(page.contact_email).to eq group_after_division1_main_contact.contact_email
        expect(page.contact_link_url).to eq group_after_division1_main_contact.contact_link_url
        expect(page.contact_link_name).to eq group_after_division1_main_contact.contact_link_name
      end
      Article::Page.find(article_page2.id).tap do |page|
        expect(page.contact_group_id).to eq group_after_division1.id
        expect(page.contact_group_contact_id).to eq group_after_division1_main_contact.id
        expect(page.contact_group_relation).to eq "related"
        expect(page.contact_charge).to eq group_after_division1_main_contact.contact_group_name
        expect(page.contact_tel).to eq group_after_division1_main_contact.contact_tel
        expect(page.contact_fax).to eq group_after_division1_main_contact.contact_fax
        expect(page.contact_email).to eq group_after_division1_main_contact.contact_email
        expect(page.contact_link_url).to eq group_after_division1_main_contact.contact_link_url
        expect(page.contact_link_name).to eq group_after_division1_main_contact.contact_link_name
      end
      Article::Page.find(article_page3.id).tap do |page|
        expect(page.contact_group_id).to eq group_after_division2.id
        expect(page.contact_group_contact_id).to eq group_after_division2_main_contact.id
        expect(page.contact_group_relation).to eq "related"
        expect(page.contact_charge).to eq group_after_division2_main_contact.contact_group_name
        expect(page.contact_tel).to eq group_after_division2_main_contact.contact_tel
        expect(page.contact_fax).to eq group_after_division2_main_contact.contact_fax
        expect(page.contact_email).to eq group_after_division2_main_contact.contact_email
        expect(page.contact_link_url).to eq group_after_division2_main_contact.contact_link_url
        expect(page.contact_link_name).to eq group_after_division2_main_contact.contact_link_name
      end
      Article::Page.find(article_page4.id).tap do |page|
        expect(page.contact_group_id).to eq group_after_division2.id
        expect(page.contact_group_contact_id).to eq group_after_division2_sub_contact.id
        expect(page.contact_group_relation).to eq "related"
        expect(page.contact_charge).to eq group_after_division2_sub_contact.contact_group_name
        expect(page.contact_tel).to eq group_after_division2_sub_contact.contact_tel
        expect(page.contact_fax).to eq group_after_division2_sub_contact.contact_fax
        expect(page.contact_email).to eq group_after_division2_sub_contact.contact_email
        expect(page.contact_link_url).to eq group_after_division2_sub_contact.contact_link_url
        expect(page.contact_link_name).to eq group_after_division2_sub_contact.contact_link_name
      end
    end
  end

  context "division with unifing contacts to main #2: 組織変更後には主連絡先のみ存在する" do
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
          },
          {
            main_state: nil, name: "name-#{unique_id}", contact_group_name: "contact_group_name-#{unique_id}",
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
    let(:sub_contacts) { source_group.contact_groups.ne(main_state: "main").to_a }

    let!(:revision) { create(:revision, site_id: site.id) }
    let(:destination1_contact1) do
      main_contact = source_group.contact_groups.where(main_state: "main").first
      {
        _id: main_contact.id.to_s, main_state: "main", name: unique_id, unifies_to_main: "enabled",
        contact_group_name: "name-#{unique_id}", contact_tel: unique_tel, contact_fax: unique_tel,
        contact_email: unique_email, contact_link_url: "/#{unique_id}/", contact_link_name: "link-#{unique_id}",
      }.with_indifferent_access
    end
    let(:destination2_contact1) do
      sub_contact = sub_contacts[1]
      {
        _id: sub_contact.id.to_s, main_state: "main", name: unique_id, unifies_to_main: "enabled",
        contact_group_name: "name-#{unique_id}", contact_tel: unique_tel, contact_fax: unique_tel,
        contact_email: unique_email, contact_link_url: "/#{unique_id}/", contact_link_name: "link-#{unique_id}",
      }.with_indifferent_access
    end
    let(:destination1) do
      {
        name: "#{root_group.name}/#{unique_id}", order: rand(1..10).to_s,
        ldap_dn: "dc=dc-#{unique_id},dc=city,dc=example,dc=jp",
        contact_groups: [ destination1_contact1 ]
      }.with_indifferent_access
    end
    let(:destination2) do
      {
        name: "#{root_group.name}/#{unique_id}", order: rand(1..10).to_s,
        ldap_dn: "dc=dc-#{unique_id},dc=city,dc=example,dc=jp",
        contact_groups: [ destination2_contact1 ]
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
      # source_group のサブ連絡先 #1
      sub_contact = sub_contacts[0]

      create(
        :article_page, cur_site: site, cur_node: article_node, group_ids: [ source_group.id ],
        contact_group_id: source_group.id, contact_group_contact_id: sub_contact.id, contact_group_relation: "related",
        contact_charge: sub_contact.contact_group_name, contact_tel: sub_contact.contact_tel,
        contact_fax: sub_contact.contact_fax, contact_email: sub_contact.contact_email,
        contact_link_url: sub_contact.contact_link_url, contact_link_name: sub_contact.contact_link_name)
    end
    let!(:article_page3) do
      # source_group のサブ連絡先 #2
      sub_contact = sub_contacts[1]

      create(
        :article_page, cur_site: site, cur_node: article_node, group_ids: [ source_group.id ],
        contact_group_id: source_group.id, contact_group_contact_id: sub_contact.id, contact_group_relation: "related",
        contact_charge: sub_contact.contact_group_name, contact_tel: sub_contact.contact_tel,
        contact_fax: sub_contact.contact_fax, contact_email: sub_contact.contact_email,
        contact_link_url: sub_contact.contact_link_url, contact_link_name: sub_contact.contact_link_name)
    end
    let!(:article_page4) do
      # source_group のサブ連絡先 #3
      sub_contact = sub_contacts[2]

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
      expect { job.perform_now(revision.name, job_opts) }.to output(include("[分割] 成功: 1, 失敗: 0\n")).to_stdout

      # check for job was succeeded
      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      group_after_division1 = Cms::Group.find(source_group.id).tap do |group_after_division|
        expect(group_after_division.contact_groups.count).to eq 1
        group_after_division.contact_groups.first.tap do |contact|
          expect(contact.name).to eq destination1_contact1[:name]
          expect(contact.main_state).to eq destination1_contact1[:main_state]
          expect(contact.contact_group_name).to eq destination1_contact1[:contact_group_name]
          expect(contact.contact_tel).to eq destination1_contact1[:contact_tel]
          expect(contact.contact_fax).to eq destination1_contact1[:contact_fax]
          expect(contact.contact_email).to eq destination1_contact1[:contact_email]
          expect(contact.contact_link_url).to eq destination1_contact1[:contact_link_url]
          expect(contact.contact_link_name).to eq destination1_contact1[:contact_link_name]
        end
      end
      group_after_division2 = Cms::Group.find_by(name: destination2[:name]).tap do |group_after_division|
        expect(group_after_division.contact_groups.count).to eq 1
        group_after_division.contact_groups.first.tap do |contact|
          expect(contact.name).to eq destination2_contact1[:name]
          expect(contact.main_state).to eq destination2_contact1[:main_state]
          expect(contact.contact_group_name).to eq destination2_contact1[:contact_group_name]
          expect(contact.contact_tel).to eq destination2_contact1[:contact_tel]
          expect(contact.contact_fax).to eq destination2_contact1[:contact_fax]
          expect(contact.contact_email).to eq destination2_contact1[:contact_email]
          expect(contact.contact_link_url).to eq destination2_contact1[:contact_link_url]
          expect(contact.contact_link_name).to eq destination2_contact1[:contact_link_name]
        end
      end
      group_after_division1_main_contact = group_after_division1.contact_groups.where(main_state: "main").first
      group_after_division2_main_contact = group_after_division2.contact_groups.where(main_state: "main").first

      Article::Page.find(article_page1.id).tap do |page|
        expect(page.contact_group_id).to eq group_after_division1.id
        expect(page.contact_group_contact_id).to eq group_after_division1_main_contact.id
        expect(page.contact_group_relation).to eq "related"
        expect(page.contact_charge).to eq group_after_division1_main_contact.contact_group_name
        expect(page.contact_tel).to eq group_after_division1_main_contact.contact_tel
        expect(page.contact_fax).to eq group_after_division1_main_contact.contact_fax
        expect(page.contact_email).to eq group_after_division1_main_contact.contact_email
        expect(page.contact_link_url).to eq group_after_division1_main_contact.contact_link_url
        expect(page.contact_link_name).to eq group_after_division1_main_contact.contact_link_name
      end
      Article::Page.find(article_page2.id).tap do |page|
        expect(page.contact_group_id).to eq group_after_division1.id
        expect(page.contact_group_contact_id).to eq group_after_division1_main_contact.id
        expect(page.contact_group_relation).to eq "related"
        expect(page.contact_charge).to eq group_after_division1_main_contact.contact_group_name
        expect(page.contact_tel).to eq group_after_division1_main_contact.contact_tel
        expect(page.contact_fax).to eq group_after_division1_main_contact.contact_fax
        expect(page.contact_email).to eq group_after_division1_main_contact.contact_email
        expect(page.contact_link_url).to eq group_after_division1_main_contact.contact_link_url
        expect(page.contact_link_name).to eq group_after_division1_main_contact.contact_link_name
      end
      Article::Page.find(article_page3.id).tap do |page|
        expect(page.contact_group_id).to eq group_after_division2.id
        expect(page.contact_group_contact_id).to eq group_after_division2_main_contact.id
        expect(page.contact_group_relation).to eq "related"
        expect(page.contact_charge).to eq group_after_division2_main_contact.contact_group_name
        expect(page.contact_tel).to eq group_after_division2_main_contact.contact_tel
        expect(page.contact_fax).to eq group_after_division2_main_contact.contact_fax
        expect(page.contact_email).to eq group_after_division2_main_contact.contact_email
        expect(page.contact_link_url).to eq group_after_division2_main_contact.contact_link_url
        expect(page.contact_link_name).to eq group_after_division2_main_contact.contact_link_name
      end
      Article::Page.find(article_page4.id).tap do |page|
        expect(page.contact_group_id).to eq group_after_division1.id
        expect(page.contact_group_contact_id).to eq group_after_division1_main_contact.id
        expect(page.contact_group_relation).to eq "related"
        expect(page.contact_charge).to eq group_after_division1_main_contact.contact_group_name
        expect(page.contact_tel).to eq group_after_division1_main_contact.contact_tel
        expect(page.contact_fax).to eq group_after_division1_main_contact.contact_fax
        expect(page.contact_email).to eq group_after_division1_main_contact.contact_email
        expect(page.contact_link_url).to eq group_after_division1_main_contact.contact_link_url
        expect(page.contact_link_name).to eq group_after_division1_main_contact.contact_link_name
      end
    end
  end

  context "divide to existing group with unifing contacts to main #1" do
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
          },
          {
            main_state: nil, name: "name-#{unique_id}", contact_group_name: "contact_group_name-#{unique_id}",
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
    let(:sub_contacts) { source_group.contact_groups.ne(main_state: "main").to_a }

    let!(:revision) { create(:revision, site_id: site.id) }
    let(:destination1_contact1) do
      main_contact = source_group.contact_groups.where(main_state: "main").first
      {
        _id: main_contact.id.to_s, main_state: "main", name: main_contact.name, unifies_to_main: "enabled",
        contact_group_name: main_contact.contact_group_name, contact_tel: main_contact.contact_tel,
        contact_fax: main_contact.contact_fax, contact_email: main_contact.contact_email,
        contact_link_url: main_contact.contact_link_url, contact_link_name: main_contact.contact_link_name,
      }.with_indifferent_access
    end
    let(:destination1_contact2) do
      sub_contact = sub_contacts[0]
      {
        _id: sub_contact.id.to_s, main_state: nil, name: sub_contact.name, unifies_to_main: "enabled",
        contact_group_name: sub_contact.contact_group_name, contact_tel: sub_contact.contact_tel,
        contact_fax: sub_contact.contact_fax, contact_email: sub_contact.contact_email,
        contact_link_url: sub_contact.contact_link_url, contact_link_name: sub_contact.contact_link_name,
      }.with_indifferent_access
    end
    let(:destination2_contact1) do
      sub_contact = sub_contacts[1]
      {
        _id: sub_contact.id.to_s, main_state: "main", name: sub_contact.name, unifies_to_main: "enabled",
        contact_group_name: sub_contact.contact_group_name, contact_tel: sub_contact.contact_tel,
        contact_fax: sub_contact.contact_fax, contact_email: sub_contact.contact_email,
        contact_link_url: sub_contact.contact_link_url, contact_link_name: sub_contact.contact_link_name,
      }.with_indifferent_access
    end
    let(:destination2_contact2) do
      sub_contact = sub_contacts[2]
      {
        _id: sub_contact.id.to_s, main_state: nil, name: sub_contact.name, unifies_to_main: "enabled",
        contact_group_name: sub_contact.contact_group_name, contact_tel: sub_contact.contact_tel,
        contact_fax: sub_contact.contact_fax, contact_email: sub_contact.contact_email,
        contact_link_url: sub_contact.contact_link_url, contact_link_name: sub_contact.contact_link_name,
      }.with_indifferent_access
    end
    let(:destination1) do
      # source_group へ分割する
      {
        name: source_group.name, order: source_group.order.to_s, ldap_dn: source_group.ldap_dn,
        contact_groups: [ destination1_contact1, destination1_contact2 ]
      }.with_indifferent_access
    end
    let(:destination2) do
      # 新しいグループへ分割する
      {
        name: "#{root_group.name}/#{unique_id}", order: rand(1..10).to_s,
        ldap_dn: "dc=dc-#{unique_id},dc=city,dc=example,dc=jp",
        contact_groups: [ destination2_contact1, destination2_contact2 ]
      }.with_indifferent_access
    end
    let!(:changeset) do
      create(:division_changeset, revision_id: revision.id, source: source_group, destinations: [ destination1, destination2 ])
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
      # source_group のサブ連絡先 #1
      sub_contact = sub_contacts[0]

      create(
        :article_page, cur_site: site, cur_node: article_node, group_ids: [ source_group.id ],
        contact_group_id: source_group.id, contact_group_contact_id: sub_contact.id, contact_group_relation: "related",
        contact_charge: sub_contact.contact_group_name, contact_tel: sub_contact.contact_tel,
        contact_fax: sub_contact.contact_fax, contact_email: sub_contact.contact_email,
        contact_link_url: sub_contact.contact_link_url, contact_link_name: sub_contact.contact_link_name)
    end
    let!(:article_page3) do
      # source_group のサブ連絡先 #2
      sub_contact = sub_contacts[1]

      create(
        :article_page, cur_site: site, cur_node: article_node, group_ids: [ source_group.id ],
        contact_group_id: source_group.id, contact_group_contact_id: sub_contact.id, contact_group_relation: "related",
        contact_charge: sub_contact.contact_group_name, contact_tel: sub_contact.contact_tel,
        contact_fax: sub_contact.contact_fax, contact_email: sub_contact.contact_email,
        contact_link_url: sub_contact.contact_link_url, contact_link_name: sub_contact.contact_link_name)
    end
    let!(:article_page4) do
      # source_group のサブ連絡先 #3
      sub_contact = sub_contacts[2]

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
      expect { job.perform_now(revision.name, job_opts) }.to output(include("[分割] 成功: 1, 失敗: 0\n")).to_stdout

      # check for job was succeeded
      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      group_after_division1 = Cms::Group.find_by(name: destination1[:name]).tap do |group_after_division|
        expect(group_after_division.contact_groups.count).to eq 2
        group_after_division.contact_groups.where(main_state: "main").first.tap do |contact|
          expect(contact.name).to eq destination1_contact1[:name]
          expect(contact.main_state).to eq destination1_contact1[:main_state]
          expect(contact.contact_group_name).to eq destination1_contact1[:contact_group_name]
          expect(contact.contact_tel).to eq destination1_contact1[:contact_tel]
          expect(contact.contact_fax).to eq destination1_contact1[:contact_fax]
          expect(contact.contact_email).to eq destination1_contact1[:contact_email]
          expect(contact.contact_link_url).to eq destination1_contact1[:contact_link_url]
          expect(contact.contact_link_name).to eq destination1_contact1[:contact_link_name]
        end
        group_after_division.contact_groups.ne(main_state: "main").first.tap do |contact|
          expect(contact.name).to eq destination1_contact2[:name]
          expect(contact.main_state).to eq destination1_contact2[:main_state]
          expect(contact.contact_group_name).to eq destination1_contact2[:contact_group_name]
          expect(contact.contact_tel).to eq destination1_contact2[:contact_tel]
          expect(contact.contact_fax).to eq destination1_contact2[:contact_fax]
          expect(contact.contact_email).to eq destination1_contact2[:contact_email]
          expect(contact.contact_link_url).to eq destination1_contact2[:contact_link_url]
          expect(contact.contact_link_name).to eq destination1_contact2[:contact_link_name]
        end
      end
      group_after_division2 = Cms::Group.find_by(name: destination2[:name]).tap do |group_after_division|
        expect(group_after_division.contact_groups.count).to eq 2
        group_after_division.contact_groups.where(main_state: "main").first.tap do |contact|
          expect(contact.name).to eq destination2_contact1[:name]
          expect(contact.main_state).to eq destination2_contact1[:main_state]
          expect(contact.contact_group_name).to eq destination2_contact1[:contact_group_name]
          expect(contact.contact_tel).to eq destination2_contact1[:contact_tel]
          expect(contact.contact_fax).to eq destination2_contact1[:contact_fax]
          expect(contact.contact_email).to eq destination2_contact1[:contact_email]
          expect(contact.contact_link_url).to eq destination2_contact1[:contact_link_url]
          expect(contact.contact_link_name).to eq destination2_contact1[:contact_link_name]
        end
        group_after_division.contact_groups.ne(main_state: "main").first.tap do |contact|
          expect(contact.name).to eq destination2_contact2[:name]
          expect(contact.main_state).to eq destination2_contact2[:main_state]
          expect(contact.contact_group_name).to eq destination2_contact2[:contact_group_name]
          expect(contact.contact_tel).to eq destination2_contact2[:contact_tel]
          expect(contact.contact_fax).to eq destination2_contact2[:contact_fax]
          expect(contact.contact_email).to eq destination2_contact2[:contact_email]
          expect(contact.contact_link_url).to eq destination2_contact2[:contact_link_url]
          expect(contact.contact_link_name).to eq destination2_contact2[:contact_link_name]
        end
      end
      # group_after_division1 = Cms::Group.find(source_group.id)
      group_after_division1_main_contact = group_after_division1.contact_groups.where(main_state: "main").first
      # group_after_division2 = Cms::Group.find_by(name: destination2[:name])
      group_after_division2_main_contact = group_after_division2.contact_groups.where(main_state: "main").first

      Article::Page.find(article_page1.id).tap do |page|
        expect(page.contact_group_id).to eq group_after_division1.id
        expect(page.contact_group_contact_id).to eq group_after_division1_main_contact.id
        expect(page.contact_group_relation).to eq "related"
        expect(page.contact_charge).to eq group_after_division1_main_contact.contact_group_name
        expect(page.contact_tel).to eq group_after_division1_main_contact.contact_tel
        expect(page.contact_fax).to eq group_after_division1_main_contact.contact_fax
        expect(page.contact_email).to eq group_after_division1_main_contact.contact_email
        expect(page.contact_link_url).to eq group_after_division1_main_contact.contact_link_url
        expect(page.contact_link_name).to eq group_after_division1_main_contact.contact_link_name
      end
      Article::Page.find(article_page2.id).tap do |page|
        expect(page.contact_group_id).to eq group_after_division1.id
        expect(page.contact_group_contact_id).to eq group_after_division1_main_contact.id
        expect(page.contact_group_relation).to eq "related"
        expect(page.contact_charge).to eq group_after_division1_main_contact.contact_group_name
        expect(page.contact_tel).to eq group_after_division1_main_contact.contact_tel
        expect(page.contact_fax).to eq group_after_division1_main_contact.contact_fax
        expect(page.contact_email).to eq group_after_division1_main_contact.contact_email
        expect(page.contact_link_url).to eq group_after_division1_main_contact.contact_link_url
        expect(page.contact_link_name).to eq group_after_division1_main_contact.contact_link_name
      end
      Article::Page.find(article_page3.id).tap do |page|
        expect(page.contact_group_id).to eq group_after_division2.id
        expect(page.contact_group_contact_id).to eq group_after_division2_main_contact.id
        expect(page.contact_group_relation).to eq "related"
        expect(page.contact_charge).to eq group_after_division2_main_contact.contact_group_name
        expect(page.contact_tel).to eq group_after_division2_main_contact.contact_tel
        expect(page.contact_fax).to eq group_after_division2_main_contact.contact_fax
        expect(page.contact_email).to eq group_after_division2_main_contact.contact_email
        expect(page.contact_link_url).to eq group_after_division2_main_contact.contact_link_url
        expect(page.contact_link_name).to eq group_after_division2_main_contact.contact_link_name
      end
      Article::Page.find(article_page4.id).tap do |page|
        expect(page.contact_group_id).to eq group_after_division2.id
        expect(page.contact_group_contact_id).to eq group_after_division2_main_contact.id
        expect(page.contact_group_relation).to eq "related"
        expect(page.contact_charge).to eq group_after_division2_main_contact.contact_group_name
        expect(page.contact_tel).to eq group_after_division2_main_contact.contact_tel
        expect(page.contact_fax).to eq group_after_division2_main_contact.contact_fax
        expect(page.contact_email).to eq group_after_division2_main_contact.contact_email
        expect(page.contact_link_url).to eq group_after_division2_main_contact.contact_link_url
        expect(page.contact_link_name).to eq group_after_division2_main_contact.contact_link_name
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

    let!(:revision) { create(:revision, site_id: site.id) }
    let(:destination1_contact) do
      main_contact = group1.contact_groups.where(main_state: "main").first
      {
        _id: main_contact.id.to_s, main_state: "main", name: main_contact.name, unifies_to_main: "enabled",
        contact_group_name: main_contact.contact_group_name, contact_tel: main_contact.contact_tel,
        contact_fax: main_contact.contact_fax, contact_email: main_contact.contact_email,
        contact_link_url: main_contact.contact_link_url, contact_link_name: main_contact.contact_link_name,
      }.with_indifferent_access
    end
    let(:destination2_contact) do
      sub_contact = group1.contact_groups.ne(main_state: "main").first
      {
        _id: sub_contact.id.to_s, main_state: "main", name: sub_contact.name, unifies_to_main: "enabled",
        contact_group_name: sub_contact.contact_group_name, contact_tel: sub_contact.contact_tel,
        contact_fax: sub_contact.contact_fax, contact_email: sub_contact.contact_email,
        contact_link_url: sub_contact.contact_link_url, contact_link_name: sub_contact.contact_link_name,
      }.with_indifferent_access
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
      job = described_class.bind(site_id: site.id, task_id: task.id)
      expect { job.perform_now(revision.name, job_opts) }.to output(include("[分割] 成功: 1, 失敗: 0\n")).to_stdout

      # check for job was succeeded
      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      group_after_division1 = Cms::Group.find_by(name: destination1[:name]).tap do |group_after_division|
        expect(group_after_division.contact_groups.count).to eq 1
        group_after_division.contact_groups.where(main_state: "main").first.tap do |contact|
          expect(contact.name).to eq destination1_contact[:name]
          expect(contact.main_state).to eq destination1_contact[:main_state]
          expect(contact.contact_group_name).to eq destination1_contact[:contact_group_name]
          expect(contact.contact_tel).to eq destination1_contact[:contact_tel]
          expect(contact.contact_fax).to eq destination1_contact[:contact_fax]
          expect(contact.contact_email).to eq destination1_contact[:contact_email]
          expect(contact.contact_link_url).to eq destination1_contact[:contact_link_url]
          expect(contact.contact_link_name).to eq destination1_contact[:contact_link_name]
        end
      end
      group_after_division2 = Cms::Group.find_by(name: destination2[:name]).tap do |group_after_division|
        expect(group_after_division.contact_groups.count).to eq 1
        group_after_division.contact_groups.where(main_state: "main").first.tap do |contact|
          expect(contact.name).to eq destination2_contact[:name]
          expect(contact.main_state).to eq destination2_contact[:main_state]
          expect(contact.contact_group_name).to eq destination2_contact[:contact_group_name]
          expect(contact.contact_tel).to eq destination2_contact[:contact_tel]
          expect(contact.contact_fax).to eq destination2_contact[:contact_fax]
          expect(contact.contact_email).to eq destination2_contact[:contact_email]
          expect(contact.contact_link_url).to eq destination2_contact[:contact_link_url]
          expect(contact.contact_link_name).to eq destination2_contact[:contact_link_name]
        end
      end
      group_after_division1_main_contact = group_after_division1.contact_groups.where(main_state: "main").first
      group_after_division2_main_contact = group_after_division2.contact_groups.where(main_state: "main").first

      Article::Page.find(article_page1.id).tap do |page|
        expect(page.contact_group_id).to eq group_after_division1.id
        expect(page.contact_group_contact_id).to eq group_after_division1_main_contact.id
        expect(page.contact_group_relation).to eq "related"
        expect(page.contact_charge).to eq group_after_division1_main_contact.contact_group_name
        expect(page.contact_tel).to eq group_after_division1_main_contact.contact_tel
        expect(page.contact_fax).to eq group_after_division1_main_contact.contact_fax
        expect(page.contact_email).to eq group_after_division1_main_contact.contact_email
        expect(page.contact_link_url).to eq group_after_division1_main_contact.contact_link_url
        expect(page.contact_link_name).to eq group_after_division1_main_contact.contact_link_name
      end
      Article::Page.find(article_page2.id).tap do |page|
        expect(page.contact_group_id).to eq group_after_division2.id
        expect(page.contact_group_contact_id).to eq group_after_division2_main_contact.id
        expect(page.contact_group_relation).to eq "related"
        expect(page.contact_charge).to eq group_after_division2_main_contact.contact_group_name
        expect(page.contact_tel).to eq group_after_division2_main_contact.contact_tel
        expect(page.contact_fax).to eq group_after_division2_main_contact.contact_fax
        expect(page.contact_email).to eq group_after_division2_main_contact.contact_email
        expect(page.contact_link_url).to eq group_after_division2_main_contact.contact_link_url
        expect(page.contact_link_name).to eq group_after_division2_main_contact.contact_link_name
      end
      Article::Page.find(article_page3.id).tap do |page|
        expect(page.contact_group_id).to eq group_after_division2.id
        expect(page.contact_group_contact_id).to eq group_after_division2_main_contact.id
        expect(page.contact_group_relation).to eq "related"
        expect(page.contact_charge).to eq group_after_division2_main_contact.contact_group_name
        expect(page.contact_tel).to eq group_after_division2_main_contact.contact_tel
        expect(page.contact_fax).to eq group_after_division2_main_contact.contact_fax
        expect(page.contact_email).to eq group_after_division2_main_contact.contact_email
        expect(page.contact_link_url).to eq group_after_division2_main_contact.contact_link_url
        expect(page.contact_link_name).to eq group_after_division2_main_contact.contact_link_name
      end
    end
  end
end
