import { Controller } from "@hotwired/stimulus"

// Popover menu anchored to a button — used by the account menu.
//
// Closes on Escape and on a click anywhere outside, which is what makes a
// popover feel like a popover rather than a stuck panel.
export default class extends Controller {
  static targets = ["menu", "button"]

  connect() {
    this.onDocumentClick = this.onDocumentClick.bind(this)
    this.onKeydown = this.onKeydown.bind(this)
    document.addEventListener("click", this.onDocumentClick)
    document.addEventListener("keydown", this.onKeydown)
    this.close()
  }

  disconnect() {
    document.removeEventListener("click", this.onDocumentClick)
    document.removeEventListener("keydown", this.onKeydown)
  }

  toggle(event) {
    event.stopPropagation()
    this.expanded ? this.close() : this.open()
  }

  open() {
    this.menuTarget.hidden = false
    this.sync(true)
  }

  close() {
    this.menuTarget.hidden = true
    this.sync(false)
  }

  onKeydown(event) {
    if (event.key !== "Escape" || !this.expanded) return

    this.close()
    if (this.hasButtonTarget) this.buttonTarget.focus()
  }

  onDocumentClick(event) {
    if (!this.expanded || this.element.contains(event.target)) return

    this.close()
  }

  sync(open) {
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", String(open))
    }
  }

  get expanded() {
    return this.hasMenuTarget && !this.menuTarget.hidden
  }
}
