require 'spec_helper'

describe Chorg::MainRunner, dbscope: :example do
  let!(:root_group) { create(:revision_root_group) }
  let!(:site) { create(:cms_site, group_ids: [root_group.id]) }
  let!(:task) { Chorg::Task.create!(name: unique_id, site_id: site.id) }
  let(:job_opts) { { 'newly_created_group_to_site' => 'add' } }

  context "unify with unifing contacts to main" do
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
    let!(:revision) { create(:revision, site_id: site.id) }
    let!(:article_node) { create(:article_node_page, cur_site: site) }
    let!(:article_page1) do
      # source_group1 の主連絡先
      main_contact = source_group1.contact_groups.where(main_state: "main").first
      create(
        :article_page, cur_site: site, cur_node: article_node,
        contact_group_id: source_group1.id, contact_group_contact_id: main_contact.id, contact_group_relation: "related",
        contact_charge: main_contact.contact_group_name, contact_tel: main_contact.contact_tel,
        contact_fax: main_contact.contact_fax, contact_email: main_contact.contact_email,
        contact_link_url: main_contact.contact_link_url, contact_link_name: main_contact.contact_link_name)
    end
    let!(:article_page2) do
      # source_group1 のサブ連絡先
      sub_contact = source_group1.contact_groups.ne(main_state: "main").first
      create(
        :article_page, cur_site: site, cur_node: article_node,
        contact_group_id: source_group1.id, contact_group_contact_id: sub_contact.id, contact_group_relation: "related",
        contact_charge: sub_contact.contact_group_name, contact_tel: sub_contact.contact_tel,
        contact_fax: sub_contact.contact_fax, contact_email: sub_contact.contact_email,
        contact_link_url: sub_contact.contact_link_url, contact_link_name: sub_contact.contact_link_name)
    end
    let!(:article_page3) do
      # source_group2 の主連絡先
      main_contact = source_group2.contact_groups.where(main_state: "main").first
      create(
        :article_page, cur_site: site, cur_node: article_node,
        contact_group_id: source_group1.id, contact_group_contact_id: main_contact.id, contact_group_relation: "related",
        contact_charge: main_contact.contact_group_name, contact_tel: main_contact.contact_tel,
        contact_fax: main_contact.contact_fax, contact_email: main_contact.contact_email,
        contact_link_url: main_contact.contact_link_url, contact_link_name: main_contact.contact_link_name)
    end
    let!(:article_page4) do
      # source_group2 のサブ連絡先
      sub_contact = source_group2.contact_groups.ne(main_state: "main").first
      create(
        :article_page, cur_site: site, cur_node: article_node,
        contact_group_id: source_group1.id, contact_group_contact_id: sub_contact.id, contact_group_relation: "related",
        contact_charge: sub_contact.contact_group_name, contact_tel: sub_contact.contact_tel,
        contact_fax: sub_contact.contact_fax, contact_email: sub_contact.contact_email,
        contact_link_url: sub_contact.contact_link_url, contact_link_name: sub_contact.contact_link_name)
    end
    let(:destination_contact) do
      {
        main_state: "main", name: "main", unifies_to_main: "enabled",
        contact_group_name: "name-#{unique_id}", contact_tel: unique_tel, contact_fax: unique_tel,
        contact_email: unique_email, contact_link_url: "/#{unique_id}/", contact_link_name: "link-#{unique_id}",
      }.with_indifferent_access
    end
    let(:destination) do
      {
        name: "#{root_group.name}/#{unique_id}", order: rand(1..10).to_s,
        ldap_dn: "dc=dc-#{unique_id},dc=city,dc=example,dc=jp",
        contact_groups: [ destination_contact ]
      }.with_indifferent_access
    end
    let!(:changeset) do
      create(:unify_changeset, revision_id: revision.id, sources: [ source_group1, source_group2 ], destinations: [ destination ])
    end

    it do
      # execute
      job = described_class.bind(site_id: site.id, task_id: task.id)
      expect { job.perform_now(revision.name, job_opts) }.to output(include("[統合] 成功: 1, 失敗: 0\n")).to_stdout

      # check for job was succeeded
      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      Cms::Group.find(source_group1.id).tap do |group|
        expect(group.name).to eq destination[:name]
        expect(group.order).to eq destination[:order].to_i
        expect(group.ldap_dn).to eq destination[:ldap_dn]
        expect(group.contact_group_name).to eq destination_contact[:contact_group_name]
        expect(group.contact_tel).to eq destination_contact[:contact_tel]
        expect(group.contact_fax).to eq destination_contact[:contact_fax]
        expect(group.contact_email).to eq destination_contact[:contact_email]
        expect(group.contact_link_url).to eq destination_contact[:contact_link_url]
        expect(group.contact_link_name).to eq destination_contact[:contact_link_name]
        expect(group.contact_groups.count).to eq 1
        group.contact_groups.first.tap do |new_contact|
          expect(new_contact.main_state).to eq "main"
          expect(new_contact.main_state).to eq destination_contact[:main_state]
          expect(new_contact.name).to eq destination_contact[:name]
          expect(new_contact.contact_group_name).to eq destination_contact[:contact_group_name]
          expect(new_contact.contact_tel).to eq destination_contact[:contact_tel]
          expect(new_contact.contact_fax).to eq destination_contact[:contact_fax]
          expect(new_contact.contact_email).to eq destination_contact[:contact_email]
          expect(new_contact.contact_link_url).to eq destination_contact[:contact_link_url]
          expect(new_contact.contact_link_name).to eq destination_contact[:contact_link_name]
        end
      end

      expect { Cms::Group.find(source_group2.id) }.to raise_error Mongoid::Errors::DocumentNotFound

      new_contact = Cms::Group.find(source_group1.id).then { |group| group.contact_groups.first }

      Article::Page.find(article_page1.id).tap do |page|
        expect(page.contact_group_id).to eq source_group1.id
        expect(page.contact_group_contact_id).to eq new_contact.id
        expect(page.contact_group_relation).to eq "related"
        expect(page.contact_charge).to eq new_contact.contact_group_name
        expect(page.contact_tel).to eq new_contact.contact_tel
        expect(page.contact_fax).to eq new_contact.contact_fax
        expect(page.contact_email).to eq new_contact.contact_email
        expect(page.contact_link_url).to eq new_contact.contact_link_url
        expect(page.contact_link_name).to eq new_contact.contact_link_name
      end
      Article::Page.find(article_page2.id).tap do |page|
        expect(page.contact_group_id).to eq source_group1.id
        expect(page.contact_group_contact_id).to eq new_contact.id
        expect(page.contact_group_relation).to eq "related"
        expect(page.contact_charge).to eq new_contact.contact_group_name
        expect(page.contact_tel).to eq new_contact.contact_tel
        expect(page.contact_fax).to eq new_contact.contact_fax
        expect(page.contact_email).to eq new_contact.contact_email
        expect(page.contact_link_url).to eq new_contact.contact_link_url
        expect(page.contact_link_name).to eq new_contact.contact_link_name
      end
    end
  end

  context "unify to existing group with unifing contacts to main" do
    let!(:source_group1) { create(:revision_new_group, order: 10) }
    let!(:source_group2) { create(:revision_new_group, order: 20) }
    let!(:destination_group) { create(:revision_new_group, order: 30) }

    let!(:revision) { create(:revision, site_id: site.id) }
    let(:destination_contact) do
      contact = source_group1.contact_groups.first
      {
        _id: contact.id.to_s, main_state: "main", name: "main", unifies_to_main: "enabled",
        contact_group_name: "name-#{unique_id}", contact_tel: unique_tel, contact_fax: unique_tel,
        contact_email: unique_email, contact_link_url: "/#{unique_id}/", contact_link_name: "link-#{unique_id}",
      }.with_indifferent_access
    end
    let(:destination) do
      {
        name: destination_group.name, order: rand(1..10).to_s,
        ldap_dn: "dc=dc-#{unique_id},dc=city,dc=example,dc=jp",
        contact_groups: [ destination_contact ]
      }.with_indifferent_access
    end
    let!(:changeset) do
      create(
        :unify_changeset, revision_id: revision.id, sources: [ source_group1, source_group2 ], destinations: [ destination ]
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
        contact_group_id: source_group1.id, contact_group_contact_id: contact.id, contact_group_relation: "related",
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
      # execute
      job = described_class.bind(site_id: site.id, task_id: task.id)
      expect { job.perform_now(revision.name, job_opts) }.to output(include("[統合] 成功: 1, 失敗: 0\n")).to_stdout

      # check for job was succeeded
      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      Cms::Group.find(destination_group.id).tap do |group|
        expect(group.name).to eq destination[:name]
        expect(group.order).to eq destination[:order].to_i
        expect(group.ldap_dn).to eq destination[:ldap_dn]
        expect(group.contact_group_name).to eq destination_contact[:contact_group_name]
        expect(group.contact_tel).to eq destination_contact[:contact_tel]
        expect(group.contact_fax).to eq destination_contact[:contact_fax]
        expect(group.contact_email).to eq destination_contact[:contact_email]
        expect(group.contact_link_url).to eq destination_contact[:contact_link_url]
        expect(group.contact_link_name).to eq destination_contact[:contact_link_name]
        expect(group.contact_groups.count).to eq 1
        group.contact_groups.first.tap do |new_contact|
          expect(new_contact.main_state).to eq "main"
          expect(new_contact.main_state).to eq destination_contact[:main_state]
          expect(new_contact.name).to eq destination_contact[:name]
          expect(new_contact.contact_group_name).to eq destination_contact[:contact_group_name]
          expect(new_contact.contact_tel).to eq destination_contact[:contact_tel]
          expect(new_contact.contact_fax).to eq destination_contact[:contact_fax]
          expect(new_contact.contact_email).to eq destination_contact[:contact_email]
          expect(new_contact.contact_link_url).to eq destination_contact[:contact_link_url]
          expect(new_contact.contact_link_name).to eq destination_contact[:contact_link_name]
        end
      end

      expect { Cms::Group.find(source_group1.id) }.to raise_error Mongoid::Errors::DocumentNotFound
      expect { Cms::Group.find(source_group2.id) }.to raise_error Mongoid::Errors::DocumentNotFound

      new_contact = Cms::Group.find(destination_group.id).then { |group| group.contact_groups.first }

      Article::Page.find(article_page1.id).tap do |page|
        expect(page.contact_group_id).to eq destination_group.id
        expect(page.contact_group_contact_id).to eq new_contact.id
        expect(page.contact_group_relation).to eq "related"
        expect(page.contact_charge).to eq new_contact.contact_group_name
        expect(page.contact_tel).to eq new_contact.contact_tel
        expect(page.contact_fax).to eq new_contact.contact_fax
        expect(page.contact_email).to eq new_contact.contact_email
        expect(page.contact_link_url).to eq new_contact.contact_link_url
        expect(page.contact_link_name).to eq new_contact.contact_link_name
      end
      Article::Page.find(article_page2.id).tap do |page|
        expect(page.contact_group_id).to eq destination_group.id
        expect(page.contact_group_contact_id).to eq new_contact.id
        expect(page.contact_group_relation).to eq "related"
        expect(page.contact_charge).to eq new_contact.contact_group_name
        expect(page.contact_tel).to eq new_contact.contact_tel
        expect(page.contact_fax).to eq new_contact.contact_fax
        expect(page.contact_email).to eq new_contact.contact_email
        expect(page.contact_link_url).to eq new_contact.contact_link_url
        expect(page.contact_link_name).to eq new_contact.contact_link_name
      end
      Article::Page.find(article_page3.id).tap do |page|
        expect(page.contact_group_id).to eq destination_group.id
        expect(page.contact_group_contact_id).to eq new_contact.id
        expect(page.contact_group_relation).to eq "related"
        expect(page.contact_charge).to eq new_contact.contact_group_name
        expect(page.contact_tel).to eq new_contact.contact_tel
        expect(page.contact_fax).to eq new_contact.contact_fax
        expect(page.contact_email).to eq new_contact.contact_email
        expect(page.contact_link_url).to eq new_contact.contact_link_url
        expect(page.contact_link_name).to eq new_contact.contact_link_name
      end
    end
  end
end
