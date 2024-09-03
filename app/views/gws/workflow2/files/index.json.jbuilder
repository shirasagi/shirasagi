json.array!(@items) do |item|
  json.partial! 'gws/workflow/files/show.json.jbuilder', item: item
end
