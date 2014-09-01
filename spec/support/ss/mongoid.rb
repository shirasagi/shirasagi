# mongoid
shared_examples "mongoid#save" do
  it { expect(build(factory).save).to eq true }
end

shared_examples "mongoid#find" do
  it { expect(model.first).not_to eq nil }
  #it { expect(model.all.size).not_to eq 0 }
end
