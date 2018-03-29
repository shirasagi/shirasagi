Inquiry_Form = function () {
  this.render();
};

Inquiry_Form.instance = null;

Inquiry_Form.render = function() {
  if (Inquiry_Form.instance) {
    return;
  }

  Inquiry_Form.instance = new Inquiry_Form();
};

Inquiry_Form.prototype.render = function() {
  $('.inquiry-form input').on('keypress', function (ev) {
    if ((ev.which && ev.which === 13) || (ev.keyCode && ev.keyCode === 13)) {
      return false;
    } else {
      return true;
    }
  });
};
