require 'spec_helper'

describe Article::Page, dbscope: :example do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:node) { create :article_node_page, cur_site: site }

  describe "#new_clone" do
    context "with basic page" do
      let!(:item) { create :article_page, cur_site: site, cur_user: user, cur_node: node }

      before do
        item.lock_until = Time.zone.now - 1.hour
        item.lock_owner = cms_user
        item.workflow_approvers = [{ level: 1, user_id: cms_user.id, state: "pending", comment: "" }]
        item.workflow_required_counts = [ false ]
        item.workflow_circulations = [{ level: 1, user_id: cms_user.id, state: "pending", comment: "" }]
        item.approved = Time.zone.now - 1.hour
        item.opendata_dataset_state = %w(none public closed).sample

        item.fields.each do |field_name, field_def|
          next if field_def.options.blank?
          next if field_def.options.dig(:metadata, :on_copy) != :clear
          next if item.send(field_name).present?

          case field_def
          when Mongoid::Fields::Standard
            if field_def.type == Array
              item.send("#{field_name}=", Array.new(1) { unique_id })
            elsif field_def.type == Hash
              item.send("#{field_name}=", { key: unique_id })
            elsif field_def.type == SS::Extensions::ObjectIds
              item.send("#{field_name}=", Array.new(1) { rand(1..10) })
            elsif field_def.type == DateTime
              item.send("#{field_name}=", Time.zone.now + rand(1..10).hours)
            else
              item.send("#{field_name}=", unique_id)
            end
          else
            item.send("#{field_name}=", unique_id)
          end
        end
        item.save!
      end

      context "before save" do
        subject { item.new_clone }

        it do
          expect(subject.persisted?).to be_falsey

          item.fields.each do |field_name, field_def|
            if field_def.options && field_def.options.dig(:metadata, :on_copy) == :clear
              if field_def.default_val.present?
                expect(subject.send(field_name)).to eq field_def.default_val
              else
                expect(subject.send(field_name)).to be_blank
              end
            end
          end
        end
      end
    end
  end
end
