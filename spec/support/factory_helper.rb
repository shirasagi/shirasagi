# find or create
def create_once(name, params = {})
  item = build(name, params)
  cond = params.presence || { name: item.name }
  item.class.where(cond).last || create(name, cond)
end

# If a validation error occurs an error will get raised.
def create!(name, params = {})
  item = build(name, params)
  item.save!
  item
end
