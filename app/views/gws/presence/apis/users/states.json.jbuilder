json.items do
  json.array!(@items) do |name, label, style, order|
    json.name name
    json.label label
    json.style style
    json.order order
  end
end
