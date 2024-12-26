require 'spec_helper'

describe Gws::Elasticsearch::Indexer::Workflow2FileJob, dbscope: :example, es: true do
  let(:site) { create(:gws_group) }
  let(:user) { gws_user }
  let(:file_path) { Rails.root.join('spec', 'fixtures', 'ss', 'logo.png') }
  let(:attachment) { tmp_ss_file(user: user, contents: File.binread(file_path), binary: true, content_type: 'image/png') }

  describe '#convert_to_doc' do
    let!(:dest_group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
    let!(:dest_user1) { create :gws_user, group_ids: [ dest_group1.id ], gws_role_ids: gws_user.gws_role_ids }
    let!(:form) do
      create(
        :gws_workflow2_form_application, cur_site: site, state: "public",
        destination_group_ids: [ dest_group1.id ], destination_user_ids: [ dest_user1.id ]
      )
    end
    let!(:column1) do
      create(:gws_column_text_field, cur_site: site, cur_form: form, input_type: "text", required: "optional")
    end
    let!(:column2) { create(:gws_column_file_upload, cur_site: site, cur_form: form, required: "optional") }
    let(:column1_value) { unique_id }

    context "approved" do
      let!(:approver_group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
      let!(:approver_user) { create :gws_user, group_ids: [ approver_group.id ], gws_role_ids: gws_user.gws_role_ids }
      let!(:circulation_group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
      let!(:circulation_user) { create :gws_user, group_ids: [ circulation_group.id ], gws_role_ids: gws_user.gws_role_ids }
      let!(:workflow) do
        item = build(
          :gws_workflow2_file, cur_site: site, cur_user: user, form: form,
          column_values: [ column1.serialize_value(column1_value), column2.serialize_value([ attachment.id ]) ],
          workflow_user_id: user.id, workflow_state: "approve", workflow_required_counts: [ false ],
          workflow_approvers: [
            { "level" => 1, "user_type" => "Gws::User", "user_id" => approver_user.id, state: "approve", comment: unique_id },
          ],
          workflow_circulations: [
            { "level" => 1, "user_id" => circulation_user.id, state: "seen", comment: "comment-#{unique_id}" },
          ],
          destination_group_ids: form.destination_group_ids, destination_user_ids: form.destination_user_ids,
          destination_treat_state: "treated"
        )
        item.update_workflow_user(site, user)
        item.update_workflow_agent(site, nil)
        item.save!
        item.class.find(item.id)
      end

      it do
        job = described_class.new
        job.site_id = site.id
        job.user_id = user.id
        job.instance_variable_set(:@id, workflow.id.to_s)
        id, doc = job.send(:convert_to_doc)
        expect(id).to eq "gws_workflow2_files-workflow2-#{workflow.id}"
        expect(doc.delete(:collection_name)).to eq "gws_workflow2_files"
        expect(doc.delete(:url)).to eq "/.g#{site.id}/workflow2/files/all/#{workflow.id}"
        expect(doc.delete(:name)).to eq workflow.name
        expect(doc.delete(:text)).to be_present
        expect(doc.delete(:release_date)).to be_blank
        expect(doc.delete(:close_date)).to be_blank
        expect(doc.delete(:released)).to eq workflow.updated.iso8601
        expect(doc.delete(:state)).to eq "closed"
        expect(doc.delete(:user_name)).to eq user.name
        doc.delete(:group_ids).tap do |group_ids|
          expect(group_ids).to have(1).items
          expect(group_ids).to include(dest_group1.id)
        end
        doc.delete(:user_ids).tap do |user_ids|
          expect(user_ids).to have(4).items
          expect(user_ids).to include(user.id, approver_user.id, circulation_user.id, dest_user1.id)
        end
        expect(doc.delete(:updated)).to eq workflow.updated.iso8601
        expect(doc.delete(:created)).to eq workflow.created.iso8601
        expect(doc).to be_blank
      end
    end

    context "agent" do
      let!(:approver_group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
      let!(:approver_user) { create :gws_user, group_ids: [ approver_group.id ], gws_role_ids: gws_user.gws_role_ids }
      let!(:circulation_group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
      let!(:circulation_user) { create :gws_user, group_ids: [ circulation_group.id ], gws_role_ids: gws_user.gws_role_ids }
      let!(:delegatee_group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
      let!(:delegatee_user) { create :gws_user, group_ids: [ delegatee_group.id ], gws_role_ids: gws_user.gws_role_ids }
      let!(:workflow) do
        item = build(
          :gws_workflow2_file, cur_site: site, cur_user: user, form: form,
          column_values: [ column1.serialize_value(column1_value), column2.serialize_value([ attachment.id ]) ],
          workflow_user_id: user.id, workflow_state: "approve", workflow_required_counts: [ false ],
          workflow_approvers: [
            { "level" => 1, "user_type" => "Gws::User", "user_id" => approver_user.id, state: "approve", comment: unique_id },
          ],
          workflow_circulations: [
            { "level" => 1, "user_id" => circulation_user.id, state: "seen", comment: "comment-#{unique_id}" },
          ],
          destination_group_ids: form.destination_group_ids, destination_user_ids: form.destination_user_ids,
          destination_treat_state: "treated"
        )
        item.update_workflow_user(site, delegatee_user)
        item.update_workflow_agent(site, user)
        item.save!
        item.class.find(item.id)
      end

      it do
        job = described_class.new
        job.site_id = site.id
        job.user_id = user.id
        job.instance_variable_set(:@id, workflow.id.to_s)
        id, doc = job.send(:convert_to_doc)
        expect(id).to eq "gws_workflow2_files-workflow2-#{workflow.id}"
        expect(doc.delete(:collection_name)).to eq "gws_workflow2_files"
        expect(doc.delete(:url)).to eq "/.g#{site.id}/workflow2/files/all/#{workflow.id}"
        expect(doc.delete(:name)).to eq workflow.name
        expect(doc.delete(:text)).to be_present
        expect(doc.delete(:release_date)).to be_blank
        expect(doc.delete(:close_date)).to be_blank
        expect(doc.delete(:released)).to eq workflow.updated.iso8601
        expect(doc.delete(:state)).to eq "closed"
        expect(doc.delete(:user_name)).to eq delegatee_user.name
        doc.delete(:group_ids).tap do |group_ids|
          expect(group_ids).to have(1).items
          expect(group_ids).to include(dest_group1.id)
        end
        doc.delete(:user_ids).tap do |user_ids|
          expect(user_ids).to have(5).items
          expect(user_ids).to include(user.id, delegatee_user.id, approver_user.id, circulation_user.id, dest_user1.id)
        end
        expect(doc.delete(:updated)).to eq workflow.updated.iso8601
        expect(doc.delete(:created)).to eq workflow.created.iso8601
        expect(doc).to be_blank
      end
    end

    context "request" do
      let!(:approver_group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
      let!(:approver_user) { create :gws_user, group_ids: [ approver_group.id ], gws_role_ids: gws_user.gws_role_ids }
      let!(:circulation_group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
      let!(:circulation_user) { create :gws_user, group_ids: [ circulation_group.id ], gws_role_ids: gws_user.gws_role_ids }
      let!(:delegatee_group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
      let!(:delegatee_user) { create :gws_user, group_ids: [ delegatee_group.id ], gws_role_ids: gws_user.gws_role_ids }
      let!(:workflow) do
        item = build(
          :gws_workflow2_file, cur_site: site, cur_user: user, form: form,
          column_values: [ column1.serialize_value(column1_value), column2.serialize_value([ attachment.id ]) ],
          workflow_user_id: user.id, workflow_state: "request", workflow_required_counts: [ false ],
          workflow_approvers: [
            { "level" => 1, "user_type" => "Gws::User", "user_id" => approver_user.id, state: "request" },
          ],
          workflow_circulations: [
            { "level" => 1, "user_id" => circulation_user.id, state: "pending" },
          ],
          destination_group_ids: form.destination_group_ids, destination_user_ids: form.destination_user_ids,
          destination_treat_state: "untreated"
        )
        item.update_workflow_user(site, delegatee_user)
        item.update_workflow_agent(site, user)
        item.save!
        item.class.find(item.id)
      end

      it do
        job = described_class.new
        job.site_id = site.id
        job.user_id = user.id
        job.instance_variable_set(:@id, workflow.id.to_s)
        id, doc = job.send(:convert_to_doc)
        expect(id).to eq "gws_workflow2_files-workflow2-#{workflow.id}"
        expect(doc.delete(:collection_name)).to eq "gws_workflow2_files"
        expect(doc.delete(:url)).to eq "/.g#{site.id}/workflow2/files/all/#{workflow.id}"
        expect(doc.delete(:name)).to eq workflow.name
        expect(doc.delete(:text)).to be_present
        expect(doc.delete(:release_date)).to be_blank
        expect(doc.delete(:close_date)).to be_blank
        expect(doc.delete(:released)).to eq workflow.updated.iso8601
        expect(doc.delete(:state)).to eq "closed"
        expect(doc.delete(:user_name)).to eq delegatee_user.name
        doc.delete(:group_ids).tap do |group_ids|
          expect(group_ids).to be_blank
        end
        doc.delete(:user_ids).tap do |user_ids|
          expect(user_ids).to have(3).items
          expect(user_ids).to include(user.id, delegatee_user.id, approver_user.id)
        end
        expect(doc.delete(:updated)).to eq workflow.updated.iso8601
        expect(doc.delete(:created)).to eq workflow.created.iso8601
        expect(doc).to be_blank
      end
    end

    context "draft" do
      # let!(:approver_group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
      # let!(:approver_user) { create :gws_user, group_ids: [ approver_group.id ], gws_role_ids: gws_user.gws_role_ids }
      # let!(:circulation_group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
      # let!(:circulation_user) { create :gws_user, group_ids: [ circulation_group.id ], gws_role_ids: gws_user.gws_role_ids }
      # let!(:delegatee_group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
      # let!(:delegatee_user) { create :gws_user, group_ids: [ delegatee_group.id ], gws_role_ids: gws_user.gws_role_ids }
      let!(:workflow) do
        item = create(
          :gws_workflow2_file, cur_site: site, cur_user: user, form: form,
          column_values: [ column1.serialize_value(column1_value), column2.serialize_value([ attachment.id ]) ],
          destination_group_ids: form.destination_group_ids, destination_user_ids: form.destination_user_ids,
          destination_treat_state: "untreated"
        )
        item.class.find(item.id)
      end

      it do
        expect(workflow.workflow_state).to be_blank
        expect(workflow.workflow_user_id).to be_blank
        expect(workflow.workflow_agent_id).to be_blank

        job = described_class.new
        job.site_id = site.id
        job.user_id = user.id
        job.instance_variable_set(:@id, workflow.id.to_s)
        id, doc = job.send(:convert_to_doc)
        expect(id).to eq "gws_workflow2_files-workflow2-#{workflow.id}"
        expect(doc.delete(:collection_name)).to eq "gws_workflow2_files"
        expect(doc.delete(:url)).to eq "/.g#{site.id}/workflow2/files/all/#{workflow.id}"
        expect(doc.delete(:name)).to eq workflow.name
        expect(doc.delete(:text)).to be_present
        expect(doc.delete(:release_date)).to be_blank
        expect(doc.delete(:close_date)).to be_blank
        expect(doc.delete(:released)).to eq workflow.updated.iso8601
        expect(doc.delete(:state)).to eq "closed"
        expect(doc.delete(:user_name)).to be_blank
        doc.delete(:group_ids).tap do |group_ids|
          expect(group_ids).to be_blank
        end
        doc.delete(:user_ids).tap do |user_ids|
          expect(user_ids).to have(1).items
          expect(user_ids).to include(user.id)
        end
        expect(doc.delete(:updated)).to eq workflow.updated.iso8601
        expect(doc.delete(:created)).to eq workflow.created.iso8601
        expect(doc).to be_blank
      end
    end
  end

  describe '#convert_file_to_doc' do
    let!(:form) { create(:gws_workflow2_form_application, cur_site: site, state: "public") }
    let!(:column1) do
      create(:gws_column_text_field, cur_site: site, cur_form: form, input_type: "text", required: "optional")
    end
    let!(:column2) { create(:gws_column_file_upload, cur_site: site, cur_form: form, required: "optional") }
    let(:column1_value) { unique_id }
    let!(:workflow) do
      create(
        :gws_workflow2_file, cur_site: site, cur_user: user, cur_form: form,
        column_values: [ column1.serialize_value(column1_value), column2.serialize_value([ attachment.id ]) ]
      )
    end

    it do
      job = described_class.new
      job.site_id = site.id
      job.user_id = user.id
      job.instance_variable_set(:@id, workflow.id.to_s)
      id, doc = job.send(:convert_file_to_doc, SS::File.find(attachment.id))
      unhandled_keys = [] if Rails.env.test?
      Gws::Elasticsearch.mappings_keys.each do |key|
        unless doc.key?(key.to_sym)
          unhandled_keys << key
        end
      end

      omittable_fields = %i[
        id mode text categories custom_group_ids permission_level member_ids member_group_ids member_custom_group_ids
        readable_member_ids readable_group_ids readable_custom_group_ids
        text_index site_id attachment
      ]
      unhandled_keys.reject! { |key| omittable_fields.include?(key.to_sym) }
      expect(unhandled_keys).to be_blank
    end
  end

  describe '.callback' do
    let!(:form) { create(:gws_workflow2_form_application, cur_site: site, state: "public") }
    let!(:column1) do
      create(:gws_column_text_field, cur_site: site, cur_form: form, input_type: "text", required: "optional")
    end
    let!(:column2) { create(:gws_column_file_upload, cur_site: site, cur_form: form, required: "optional") }
    let(:column1_value) { unique_id }

    before do
      # enable elastic search
      site.menu_elasticsearch_state = 'show'
      site.save!

      # gws:es:ingest:init
      Gws::Elasticsearch.init_ingest(site: site)
      # gws:es:drop
      Gws::Elasticsearch.drop_index(site: site) rescue nil
      # gws:es:create_indexes
      Gws::Elasticsearch.create_index(site: site)
    end

    context 'when model was created' do
      it do
        workflow = nil
        perform_enqueued_jobs do
          expectation = expect do
            workflow = create(
              :gws_workflow2_file, cur_site: site, cur_user: user, cur_form: form,
              column_values: [ column1.serialize_value(column1_value), column2.serialize_value([ attachment.id ]) ]
            )
          end
          expectation.to change { performed_jobs.size }.by(1)
        end

        # wait for indexing
        Gws::Elasticsearch.refresh_index(site: site)

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
          expect(es_docs["hits"]["hits"].length).to eq 2
          es_docs["hits"]["hits"][0].tap do |es_doc|
            expect(es_doc["_id"]).to eq "gws_workflow2_files-workflow2-#{workflow.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/workflow2/files/all/#{workflow.id}"
          end
          es_docs["hits"]["hits"][1].tap do |es_doc|
            expect(es_doc["_id"]).to eq "file-#{attachment.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/workflow2/files/all/#{workflow.id}#file-#{attachment.id}"
          end
        end
      end
    end

    context 'when model was updated' do
      let!(:workflow) do
        create(
          :gws_workflow2_file, cur_site: site, cur_user: user, cur_form: form,
          column_values: [ column1.serialize_value(column1_value), column2.serialize_value([ attachment.id ]) ]
        )
      end

      it do
        perform_enqueued_jobs do
          expectation = expect do
            workflow.column_values = [ column1.serialize_value(column1_value), column2.serialize_value([]) ]
            workflow.save!
          end
          expectation.to change { performed_jobs.size }.by(1)
        end

        # wait for indexing
        Gws::Elasticsearch.refresh_index(site: site)

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
          # confirm that file was removed from topic
          expect(es_docs["hits"]["hits"].length).to eq 1
          es_docs["hits"]["hits"][0].tap do |es_doc|
            expect(es_doc["_id"]).to eq "gws_workflow2_files-workflow2-#{workflow.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/workflow2/files/all/#{workflow.id}"
          end
        end
      end
    end

    context 'when model was destroyed' do
      let!(:workflow) do
        create(
          :gws_workflow2_file, cur_site: site, cur_user: user, cur_form: form,
          column_values: [ column1.serialize_value(column1_value), column2.serialize_value([ attachment.id ]) ]
        )
      end

      it do
        perform_enqueued_jobs do
          expectation = expect do
            workflow.destroy
          end
          expectation.to change { performed_jobs.size }.by(1)
        end

        # wait for indexing
        Gws::Elasticsearch.refresh_index(site: site)

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
          expect(es_docs["hits"]["hits"].length).to eq 0
        end
      end
    end

    context 'when model was soft deleted' do
      let!(:workflow) do
        create(
          :gws_workflow2_file, cur_site: site, cur_user: user, cur_form: form,
          column_values: [ column1.serialize_value(column1_value), column2.serialize_value([ attachment.id ]) ]
        )
      end

      it do
        perform_enqueued_jobs do
          expectation = expect do
            workflow.deleted = Time.zone.now
            workflow.save!
          end
          expectation.to change { performed_jobs.size }.by(1)
        end

        # wait for indexing
        Gws::Elasticsearch.refresh_index(site: site)

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
          expect(es_docs["hits"]["hits"].length).to eq 0
        end
      end
    end
  end
end
