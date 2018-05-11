FILL_CKEDITOR_SCRIPT = "
  $(arguments[0]).text(arguments[1]);
  CKEDITOR.instances[arguments[0].id].setData(arguments[1]);
".freeze

def fill_in_ckeditor(locator, options = {})
  with = options.delete(:with)
  options[:visible] = :all
  element = find(:fillable_field, locator, options)

  page.execute_script(FILL_CKEDITOR_SCRIPT, element, with)
end
