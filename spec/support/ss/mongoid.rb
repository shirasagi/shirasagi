# mongoid
shared_examples "mongoid#save" do
  it { expect { build(factory).save! }.not_to raise_error }
end

shared_examples "mongoid#find" do
  it { expect(model.first).not_to eq nil }
end
