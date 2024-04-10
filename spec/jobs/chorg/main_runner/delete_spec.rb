require 'spec_helper'

describe Chorg::MainRunner, dbscope: :example do
  let!(:root_group) { create(:revision_root_group) }
  let!(:site) { create(:cms_site, group_ids: [ root_group.id ]) }
  let!(:task) { Chorg::Task.create!(name: unique_id, site_id: site.id) }
  let(:job_opts) { { 'newly_created_group_to_site' => 'add' } }

  context "with delete" do
    let!(:source_group) { create(:revision_new_group) }
    let!(:revision) { create(:revision, site_id: site.id) }
    let!(:source_page) { create(:revision_page, cur_site: site, group: source_group) }
    let!(:changeset) { create(:delete_changeset, revision_id: revision.id, source: source_group) }

    context 'with default delete_method (disable_if_possible)' do
      it do
        # execute
        job = described_class.bind(site_id: site.id, task_id: task.id)
        expect { ss_perform_now(job, revision.name, job_opts) }.to output(include("[廃止] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        # check group
        expect(Cms::Group.unscoped.where(id: source_group.id).first.active?).to be_falsey

        # check page
        Cms::Page.find(source_page.id).tap do |page_after_delete|
          expect(page_after_delete.group_ids).to eq [ source_group.id ]
          expect(page_after_delete.filename).to eq source_page.filename
          expect(page_after_delete.contact_group_id).to eq source_group.id
          main_source_contact = source_group.contact_groups.where(main_state: "main").first
          expect(page_after_delete.contact_group_contact_id).to eq main_source_contact.id
          expect(page_after_delete.contact_group_relation).to eq "related"
          expect(page_after_delete.contact_group_name).to eq source_page.contact_group_name
          expect(page_after_delete.contact_charge).to eq source_page.contact_charge
          expect(page_after_delete.contact_tel).to eq source_page.contact_tel
          expect(page_after_delete.contact_fax).to eq source_page.contact_fax
          expect(page_after_delete.contact_email).to eq source_page.contact_email
          expect(page_after_delete.contact_postal_code).to eq source_page.contact_postal_code
          expect(page_after_delete.contact_address).to eq source_page.contact_address
          expect(page_after_delete.contact_link_url).to eq source_page.contact_link_url
          expect(page_after_delete.contact_link_name).to eq source_page.contact_link_name
        end

        task.reload
        expect(task.state).to eq 'completed'
        expect(task.entity_logs.count).to eq 1
        expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['class']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['id']).to eq source_group.id.to_s
        expect(task.entity_logs[0]['deletes']).to include('name', 'contact_email')
      end
    end

    context 'with always_delete' do
      before do
        revision.delete_method = 'always_delete'
        revision.save!
      end

      it do
        # execute
        job = described_class.bind(site_id: site.id, task_id: task.id)
        expect { ss_perform_now(job, revision.name, job_opts) }.to output(include("[廃止] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        # check group
        expect(Cms::Group.unscoped.where(id: source_group.id).first).to be_nil

        # check page
        Cms::Page.find(source_page.id).tap do |page_after_delete|
          expect(page_after_delete.group_ids).to eq [ source_group.id ]
          expect(page_after_delete.filename).to eq source_page.filename
          expect(page_after_delete.contact_group_id).to eq source_group.id
          main_source_contact = source_group.contact_groups.where(main_state: "main").first
          expect(page_after_delete.contact_group_contact_id).to eq main_source_contact.id
          expect(page_after_delete.contact_group_relation).to eq "related"
          expect(page_after_delete.contact_group_name).to eq source_page.contact_group_name
          expect(page_after_delete.contact_charge).to eq source_page.contact_charge
          expect(page_after_delete.contact_tel).to eq source_page.contact_tel
          expect(page_after_delete.contact_fax).to eq source_page.contact_fax
          expect(page_after_delete.contact_email).to eq source_page.contact_email
          expect(page_after_delete.contact_postal_code).to eq source_page.contact_postal_code
          expect(page_after_delete.contact_address).to eq source_page.contact_address
          expect(page_after_delete.contact_link_url).to eq source_page.contact_link_url
          expect(page_after_delete.contact_link_name).to eq source_page.contact_link_name
        end

        task.reload
        expect(task.state).to eq 'completed'
        expect(task.entity_logs.count).to eq 1
        expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['class']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['id']).to eq source_group.id.to_s
        expect(task.entity_logs[0]['deletes']).to include('name', 'contact_email')
      end
    end
  end
end
