# mongoid
shared_examples "mongoid#save" do |opts = {}|
  if opts[:presence]
    context "invalid" do
      opts[:presence].each do |name|
        it name do
          item = build(factory)
          item.send("#{name}=", nil)
          expect(item.save).to eq false
        end
      end
    end
  else
    context "valid" do
      it do
        item = build(factory)
        expect(item.save).to eq true
      end
    end
  end
end

shared_examples "mongoid#find" do
  it { expect(model.first).not_to eq nil }
  #it { expect(model.all.size).not_to eq 0 }
end
