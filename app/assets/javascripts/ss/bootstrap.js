//= require popper.js/dist/umd/popper
//= require bootstrap-material-design/dist/js/bootstrap-material-design

$(document).ready(function () {
  // You must set autofill to false.
  // If you absent, you can see `change` event is fired millions of times
  //
  // see: https://github.com/FezVrasta/bootstrap-material-design/issues/1102
  $('body').bootstrapMaterialDesign({ autofill: false });
});
