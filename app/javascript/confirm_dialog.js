import { Turbo } from "@hotwired/turbo-rails"

// Point data-turbo-confirm at the app's own dialog instead of the browser's
// confirm(), which cannot be styled and looks nothing like the rest of the
// page. Falls back to confirm() if the dialog is missing or <dialog> is not
// supported, so a confirmation is never silently skipped.
Turbo.setConfirmMethod((message) => {
  const dialog = document.getElementById("confirm-dialog")

  if (!dialog || typeof dialog.showModal !== "function") {
    return Promise.resolve(window.confirm(message))
  }

  dialog.querySelector("[data-confirm-message]").textContent = message
  dialog.returnValue = "cancel"
  dialog.showModal()

  return new Promise((resolve) => {
    dialog.addEventListener(
      "close",
      () => resolve(dialog.returnValue === "confirm"),
      { once: true }
    )
  })
})
