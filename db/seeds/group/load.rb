# coding: utf-8

Dir.chdir @root = File.dirname(__FILE__)

## -------------------------------------
puts "groups:"

def save_group(data)
  puts "  #{data[:name]}"
  cond = { name: data[:name] }
  
  item = SS::Group.find_or_create_by cond
  item.update
end

save_group name: "A部/A01課"
save_group name: "A部/A02課"
save_group name: "B部/B01課"
save_group name: "B部/B02課"
