import DialogController from "../../ss/dialog_controller";

export default class extends DialogController {
  apply(dialog) {
    if (!dialog.returnValue) {
      // dialog is just closed
      return;
    }

    let returnPath;
    dialog.returnValue.forEach((value) => {
      if (value[0] === "return_path") {
        returnPath = value[1];
      }
    });
    if (returnPath) {
      location.href = returnPath;
    }
  }
}
