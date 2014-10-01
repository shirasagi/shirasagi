# find or create
def create_once(name, params = {})
  item = build(name, params)
  cond = params.presence || { name: item.name }
  item.class.where(cond).last || create(name, cond)
end
