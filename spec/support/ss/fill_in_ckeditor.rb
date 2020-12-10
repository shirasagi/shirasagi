FILL_CKEDITOR_SCRIPT = "
  (function(element, text, resolve) {
    var ckeditor = CKEDITOR.instances[element.id];
    if (!ckeditor) {
      resolve(false);
      return;
    }

    $(element).text(text);
    ckeditor.setData(text, { callback: function() { resolve(true); } });
  })(arguments[0], arguments[1], arguments[2]);
".freeze

# CKEditor に html を設定する
#
# CKEditor の setData メソッドを用いて HTML を設定する。
# CKEditor の setData メソッドは非同期のため、HTML 設定直後にアクセシビリティのチェックや携帯データサイズチェックを実行すると、
# setData 完了前（つまり空）の HTML でチェックを実行していまし、正しくチェックができない場合がある。
#
# そこで、本メソッドでは setData の完了まで待機する。
#
# 参照: https://ckeditor.com/docs/ckeditor4/latest/api/CKEDITOR_editor.html#method-setData
def fill_in_ckeditor(locator, options = {})
  with = options.delete(:with)
  options[:visible] = :all
  element = find(:fillable_field, locator, options)

  ret = page.evaluate_async_script(FILL_CKEDITOR_SCRIPT, element, with)
  expect(ret).to be_truthy
end
