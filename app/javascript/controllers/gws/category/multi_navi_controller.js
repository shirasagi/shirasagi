import DialogController from "../../ss/dialog_controller";

export default class extends DialogController {
  apply(dialog) {
    if (!dialog.formData) {
      // dialog is just closed
      return;
    }

    const returnPath = dialog.formData.get("return_path")
    if (returnPath) {
      location.href = returnPath;
    }
  }
}
