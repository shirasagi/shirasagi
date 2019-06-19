## -------------------------------------
puts "# facility/category"

def create_facility_category(data)
  create_item(Gws::Facility::Category, data)
end

@fc_cate = [
  create_facility_category(name: "会議室", order: 1),
  create_facility_category(name: "公用車", order: 2)
]

## -------------------------------------
puts "# facility/item"

def create_facility_item(data)
  create_item(Gws::Facility::Item, data)
end

@fc_item = [
  create_facility_item(name: "会議室101", order: 1, category_id: @fc_cate[0].id),
  create_facility_item(name: "会議室102", order: 2, category_id: @fc_cate[0].id),
  create_facility_item(name: "公用車1", order: 10, category_id: @fc_cate[1].id),
  create_facility_item(name: "公用車2", order: 11, category_id: @fc_cate[1].id)
]
