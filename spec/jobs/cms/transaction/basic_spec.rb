require 'spec_helper'
describe Cms::TransactionJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:plan) { create :cms_transaction_plan }

  context "no execute_at" do
    let!(:unit1) { create :cms_transaction_unit_command, plan: plan, order: 10 }
    let!(:unit2) { create :cms_transaction_unit_command, plan: plan, order: 20 }
    let!(:unit3) { create :cms_transaction_unit_command, plan: plan, order: 30 }

    it do
      expectation = expect { ss_perform_now(described_class.bind(site_id: site.id), plan_id: plan.id) }
      expectation.to output(include(unit1.long_name)).to_stdout
      expectation.to output(include(unit2.long_name)).to_stdout
      expectation.to output(include(unit3.long_name)).to_stdout
    end
  end

  context "execute_at exists" do
    let!(:now) { Time.zone.now.change(sec: 0) }
    let!(:execute_at1) { now.advance(hours: -1) }
    let!(:execute_at2) { now }
    let!(:execute_at3) { now.advance(hours: 1) }

    let!(:unit1) { create :cms_transaction_unit_command, plan: plan, order: 10, execute_at: execute_at1 }
    let!(:unit2) { create :cms_transaction_unit_command, plan: plan, order: 20, execute_at: execute_at2 }
    let!(:unit3) { create :cms_transaction_unit_command, plan: plan, order: 30, execute_at: execute_at3 }

    before do
      Timecop.scale(3600)
    end
    after do
      Timecop.return
    end

    it do
      ss_perform_now(described_class.bind(site_id: site.id), plan_id: plan.id)
      expectation = expect { ss_perform_now(described_class.bind(site_id: site.id), plan_id: plan.id) }
      expectation.to output(include(unit1.long_name)).to_stdout
      expectation.to output(include(unit2.long_name)).to_stdout
      expectation.to output(include(unit3.long_name)).to_stdout
    end
  end
end
