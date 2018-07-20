## -------------------------------------
puts "# link"

def create_link(data)
  create_item(Gws::Link, data)
end

create_link name: "#{@site.name}について", links: [ { name: "SHIRASAGI", url: "http://ss-proj.org/" } ]
