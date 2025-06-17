require 'spec_helper'

describe Gws::Tabular::File, type: :model, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:space) { create :gws_tabular_space, cur_site: site }
  let(:workflow_state) { 'disabled' }
  let!(:form) do
    create(
      :gws_tabular_form, cur_site: site, cur_space: space, state: 'publishing', revision: 1,
      workflow_state: workflow_state
    )
  end

  context "with file_upload_field" do
    let(:required) { "optional" }
    let(:index_state) { 'none' }
    let(:export_state) { 'none' }
    let(:allowed_extensions) { nil }
    let!(:column1) do
      create(
        :gws_tabular_column_file_upload_field, cur_site: site, cur_form: form, required: required,
        index_state: index_state, export_state: export_state, allowed_extensions: allowed_extensions
      )
    end
    let(:file_model) { Gws::Tabular::File[form.current_release] }

    before do
      site.path_id = unique_id
      site.save!

      Gws::Tabular::FormPublishJob.bind(site_id: site, user_id: user).perform_now(form.id.to_s)

      expect(Gws::Job::Log.count).to eq 1
      Gws::Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      form.reload
      expect(form.state).to eq 'public'
    end

    context "when required is 'required'" do
      let(:required) { "required" }

      it do
        file = file_model.new(cur_site: site, cur_space: space, cur_form: form)
        expect(file.valid?).to be_falsey
        # puts file.errors.full_messages.join("\n")
        expect(file.errors["col_#{column1.id}"]).to have(1).items
        message = I18n.t("errors.messages.blank")
        expect(file.errors["col_#{column1.id}"]).to include(message)
        expect(file.errors.full_messages).to have(1).items
        full_message = I18n.t("errors.format", attribute: column1.name, message: message)
        expect(file.errors.full_messages).to include(full_message)
      end
    end

    context "when index_state is 'asc'" do
      let(:index_state) { 'asc' }

      it do
        coll = file_model.collection
        index_view = coll.indexes
        index = index_view.get("col_#{column1.id}_id" => 1)
        expect(index).to be_present
        expect(index[:unique]).to be_falsey
      end
    end

    context "when index_state is 'desc'" do
      let(:index_state) { 'desc' }

      it do
        coll = file_model.collection
        index_view = coll.indexes
        index = index_view.get("col_#{column1.id}_id" => -1)
        expect(index).to be_present
        expect(index[:unique]).to be_falsey
      end
    end

    context "when allowed_extensions is '.pdf'" do
      let(:allowed_extensions) { %w(.pdf) }

      context "when attachment is pdf" do
        it do
          path = "#{Rails.root}/spec/fixtures/ss/shirasagi.pdf"
          attachment = tmp_ss_file(site: site, user: user, contents: path, basename: "shirasagi.pdf")

          file = file_model.new(cur_site: site, cur_user: user, cur_space: space, cur_form: form)
          file.send("col_#{column1.id}=", attachment)
          expect(file.valid?).to be_truthy
        end
      end

      context "when attachment is pdf with large ext" do
        it do
          path = "#{Rails.root}/spec/fixtures/ss/shirasagi.pdf"
          attachment = tmp_ss_file(site: site, user: user, contents: path, basename: "shirasagi.PDF")

          file = file_model.new(cur_site: site, cur_user: user, cur_space: space, cur_form: form)
          file.send("col_#{column1.id}=", attachment)
          expect(file.valid?).to be_truthy
        end
      end

      context "when attachment is png" do
        it do
          path = "#{Rails.root}/spec/fixtures/ss/logo.png"
          attachment = tmp_ss_file(site: site, user: user, contents: path, basename: "logo.png")

          file = file_model.new(cur_site: site, cur_user: user, cur_space: space, cur_form: form)
          file.send("col_#{column1.id}=", attachment)
          expect(file.valid?).to be_falsey
          # puts file.errors.full_messages.join("\n")
          expect(file.errors["col_#{column1.id}_id"]).to have(1).items
          message = I18n.t("errors.messages.unable_to_accept_file", allowed_format_list: allowed_extensions.join(" / "))
          expect(file.errors["col_#{column1.id}_id"]).to include(message)
          expect(file.errors.full_messages).to have(1).items
          full_message = I18n.t("errors.format", attribute: column1.name, message: message)
          expect(file.errors.full_messages).to include(full_message)
        end
      end
    end

    context "with export_state" do
      let(:workflow_state) { %w(disabled enabled).sample }

      let(:attachment_path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }
      let!(:attachment) { tmp_ss_file(site: site, user: user, contents: attachment_path, basename: 'logo.png') }
      let(:file_model) { Gws::Tabular::File[form.current_release] }
      let!(:file) do
        file = file_model.new(cur_site: site, cur_space: space, cur_form: form, cur_user: user)
        file.send("col_#{column1.id}=", attachment)
        if workflow_state == 'enabled'
          file.workflow_user = user
          file.workflow_state = 'approve'
          file.destination_treat_state = 'no_need_to_treat'
          if file.is_a?(SS::Release)
            file.state = 'public'
            file.released = Time.zone.now
            file.release_date = Time.zone.now
            file.close_date = Time.zone.now.since(2.weeks)
          end
        end
        file.save!

        file_model.find(file.id)
      end

      context "export_state: 'none' => 'public'" do
        let(:export_state) { 'none' }
        let(:export_state_2nd) { 'public' }

        before do
          SS::File.find(attachment.id).tap do |afeter_attached|
            public_path = Gws.public_file_path(site, afeter_attached)
            expect(::File.exist?(public_path)).to be_falsey

            # Mongoid 9.0.2 以降、グローバルレジストリを通じてカスタム多形型をサポートするようになった。
            # この影響だと思うが owner_item_type が unset になる現象を確認したので
            # owner_item_type が適切に設定されていることを確認する。
            expect(afeter_attached.owner_item_id).to eq file.id
            expect(afeter_attached.owner_item_type).to eq file.class.name
          end

          form.update!(state: 'publishing', revision: form.revision + 1)
          column1.update!(export_state: export_state_2nd)
        end

        it do
          perform_enqueued_jobs do
            Gws::Tabular::FormPublishJob.bind(site_id: site, user_id: user).perform_now(form.id.to_s)
          end

          expect(Gws::Job::Log.count).to be > 0
          Gws::Job::Log.all.each do |log|
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
          end

          SS::File.find(attachment.id).tap do |afeter_attached|
            public_path = Gws.public_file_path(site, afeter_attached)
            expect(::File.size(public_path)).to eq afeter_attached.size

            # Mongoid 9.0.2 以降、グローバルレジストリを通じてカスタム多形型をサポートするようになった。
            # この影響だと思うが owner_item_type が unset になる現象を確認したので
            # owner_item_type が適切に設定されていることを確認する。
            expect(afeter_attached.owner_item_id).to eq file.id
            expect(afeter_attached.owner_item_type).to eq file.class.name
          end
        end
      end

      context "export_state: 'public' => 'none'" do
        let(:export_state) { 'public' }
        let(:export_state_2nd) { 'none' }

        before do
          SS::File.find(attachment.id).tap do |afeter_attached|
            public_path = Gws.public_file_path(site, afeter_attached)
            expect(::File.size(public_path)).to eq attachment.size

            # Mongoid 9.0.2 以降、グローバルレジストリを通じてカスタム多形型をサポートするようになった。
            # この影響だと思うが owner_item_type が unset になる現象を確認したので
            # owner_item_type が適切に設定されていることを確認する。
            expect(afeter_attached.owner_item_id).to eq file.id
            expect(afeter_attached.owner_item_type).to eq file.class.name
          end

          form.update!(state: 'publishing', revision: form.revision + 1)
          column1.update!(export_state: export_state_2nd)
        end

        it do
          perform_enqueued_jobs do
            Gws::Tabular::FormPublishJob.bind(site_id: site, user_id: user).perform_now(form.id.to_s)
          end

          expect(Gws::Job::Log.count).to be > 0
          Gws::Job::Log.all.each do |log|
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
          end

          SS::File.find(attachment.id).tap do |afeter_attached|
            public_path = Gws.public_file_path(site, afeter_attached)
            expect(::File.exist?(public_path)).to be_falsey

            # Mongoid 9.0.2 以降、グローバルレジストリを通じてカスタム多形型をサポートするようになった。
            # この影響だと思うが owner_item_type が unset になる現象を確認したので
            # owner_item_type が適切に設定されていることを確認する。
            expect(afeter_attached.owner_item_id).to eq file.id
            expect(afeter_attached.owner_item_type).to eq file.class.name
          end
        end
      end

      context "public file is deleted when file is destroyed" do
        let(:export_state) { 'public' }

        it do
          save_public_path = nil
          SS::File.find(attachment.id).tap do |afeter_attached|
            public_path = Gws.public_file_path(site, afeter_attached)
            expect(::File.size(public_path)).to eq attachment.size
            save_public_path = public_path

            # Mongoid 9.0.2 以降、グローバルレジストリを通じてカスタム多形型をサポートするようになった。
            # この影響だと思うが owner_item_type が unset になる現象を確認したので
            # owner_item_type が適切に設定されていることを確認する。
            expect(afeter_attached.owner_item_id).to eq file.id
            expect(afeter_attached.owner_item_type).to eq file.class.name
          end

          expect(file.destroy).to be_truthy

          expect(::File.exist?(save_public_path)).to be_falsey
        end
      end
    end

    context "#to_liquid" do
      let(:ss_file) { tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", basename: 'logo.png') }
      let(:item) do
        item = file_model.new(cur_site: site, cur_space: space, cur_form: form)
        item.send("col_#{column1.id}=", ss_file)
        item.save!

        file_model.find(item.id)
      end

      it do
        result = "{{ item.values[\"#{column1.name}\"].url -}}"
          .then { Liquid::Template.parse(_1) }
          .then { _1.render({ "item" => item }).to_s.strip }
        expect(result).to eq ss_file.url

        result = <<~SOURCE
          {% if item.values[\"#{column1.name}\"].image? -%}
            yes
          {% else -%}
            no
          {% endif -%}
        SOURCE
          .then { Liquid::Template.parse(_1) }
          .then { _1.render({ "item" => item }).to_s.strip }
        expect(result).to eq "yes"

        result = "{{ item.values[\"#{column1.name}\"].thumb_url -}}"
          .then { Liquid::Template.parse(_1) }
          .then { _1.render({ "item" => item }).to_s.strip }
        expect(result).to eq ss_file.thumb_url

        # ``#thumb` は export されていない
        # result = "{{ item.values[\"#{column1.name}\"].thumb.url -}}"
        #   .then { Liquid::Template.parse(_1) }
        #   .then { _1.render({ "item" => item }).to_s.strip }
        # expect(result).to eq ss_file.thumb.url
      end
    end
  end
end
