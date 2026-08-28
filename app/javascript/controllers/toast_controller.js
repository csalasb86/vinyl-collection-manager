import { Controller } from "@hotwired/stimulus"

// A dismissible toast.
//
// Notices fade out on their own — they confirm something that already worked.
// Errors stay until dismissed: they carry something the user still has to act
// on, and a message that vanishes before it is read is worse than none.
export default class extends Controller {
  static values = { dismissAfter: { type: Number, default: 0 } }

  connect() {
    if (this.dismissAfterValue > 0) {
      this.timeout = setTimeout(() => this.dismiss(), this.dismissAfterValue)
    }
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  dismiss() {
    clearTimeout(this.timeout)
    this.element.remove()
  }

  // Hovering means the user is still reading it.
  hold() {
    clearTimeout(this.timeout)
  }
}
