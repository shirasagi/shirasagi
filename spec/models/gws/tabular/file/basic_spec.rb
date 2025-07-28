require 'spec_helper'

describe Gws::Tabular::File, type: :model, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:space) { create :gws_tabular_space, cur_site: site }
  let(:workflow_state) { 'disabled' }
  let!(:form) do
    create(
      :gws_tabular_form, cur_site: site, cur_space: space, state: 'publishing', revision: 1,
      workflow_state: workflow_state)
  end

  context "without columns" do
    before do
      Gws::Tabular::FormPublishJob.bind(site_id: site, user_id: user).perform_now(form.id.to_s)

      expect(Gws::Job::Log.count).to eq 1
      Gws::Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      form.reload
      expect(form.state).to eq 'public'
    end

    context "when workflow_state is 'disabled'" do
      let(:workflow_state) { 'disabled' }

      it do
        file = Gws::Tabular::File[form.current_release].new(cur_site: site, cur_space: space, cur_form: form)
        expect(file.valid?).to be_truthy
      end
    end

    context "when workflow_state is 'enabled'" do
      let(:workflow_state) { 'enabled' }

      it do
        file_model = Gws::Tabular::File[form.current_release]
        file = file_model.new(cur_site: site, cur_space: space, cur_form: form)
        expect(file.valid?).to be_falsey
        # puts file.errors.full_messages.join("\n")
        expect(file.errors[:destination_treat_state]).to have(1).items
        expect(file.errors[:destination_treat_state]).to include(I18n.t("errors.messages.blank"))
        expect(file.errors.full_messages).to have(1).items
        message = I18n.t("errors.messages.blank")
        message = I18n.t("errors.format", attribute: file_model.t(:destination_treat_state), message: message)
        expect(file.errors.full_messages).to include(message)
      end
    end

    context "#to_liquid" do
      let(:file_model) { Gws::Tabular::File[form.current_release] }
      let(:item) do
        item = file_model.new(cur_site: site, cur_space: space, cur_form: form)
        if workflow_state == "enabled"
          item.destination_treat_state = %w(untreated treated).sample
        end
        item.save!

        file_model.find(item.id)
      end

      context "#updated" do
        it do
          result = "{{ item.updated || ss_date }}"
            .then { Liquid::Template.parse(_1) }
            .then { _1.render({ "item" => item }).to_s.strip }
          expect(result).to eq I18n.l(item.updated.to_date)

          result = "{{ item.updated || ss_time }}"
            .then { Liquid::Template.parse(_1) }
            .then { _1.render({ "item" => item }).to_s.strip }
          expect(result).to eq I18n.l(item.updated.in_time_zone)
        end
      end

      context "#created" do
        it do
          result = "{{ item.created || ss_date }}"
            .then { Liquid::Template.parse(_1) }
            .then { _1.render({ "item" => item }).to_s.strip }
          expect(result).to eq I18n.l(item.updated.to_date)

          result = "{{ item.created || ss_time }}"
            .then { Liquid::Template.parse(_1) }
            .then { _1.render({ "item" => item }).to_s.strip }
          expect(result).to eq I18n.l(item.updated.in_time_zone)
        end
      end

      context "#destination_treat_state" do
        let(:workflow_state) { 'enabled' }

        it do
          result = "{{ item.destination_treat_state }}"
            .then { Liquid::Template.parse(_1) }
            .then { _1.render({ "item" => item }).to_s.strip }
          expect(result).to eq item.destination_treat_state

          result = "{{ item.destination_treat }}"
            .then { Liquid::Template.parse(_1) }
            .then { _1.render({ "item" => item }).to_s.strip }
          expect(result).to eq item.label(:destination_treat_state)
        end
      end
    end
  end
end
