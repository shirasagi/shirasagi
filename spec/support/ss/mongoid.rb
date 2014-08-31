# mongoid
shared_examples "mongoid#save" do |opts = {}|
  if opts[:presence]
    context "invalid" do
      opts[:presence].each do |name|
        it name do
          item = factory
          item = build(factory) if Symbol === item
          item.send("#{name}=", nil)
          expect(item.save).to eq false
        end
      end
    end
  else
    context "valid" do
      it do
        item = factory
        item = build(factory) if Symbol === item
        expect(item.save).to eq true
      end
    end
  end
end

shared_examples "mongoid#find" do
  it { expect(model.first).not_to eq nil }
  it { expect(model.where({ id: -1 }).first).to eq nil }
  it { expect(model.all.size).not_to eq 0 }
  it { expect(model.where({ id: -1 }).all.size).to eq 0 }
end
