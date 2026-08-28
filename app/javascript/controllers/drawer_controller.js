import { Controller } from "@hotwired/stimulus"

// Mobile navigation panel.
//
// A disclosure that expands below the bar rather than an overlay sheet: it
// stays in the document flow, so it needs no focus trap and no scroll lock,
// and the tab order stays correct on its own.
export default class extends Controller {
  static targets = ["panel", "button", "iconOpen", "iconClose"]
  static values = {
    openLabel: { type: String, default: "Open menu" },
    closeLabel: { type: String, default: "Close menu" }
  }

  connect() {
    this.onKeydown = this.onKeydown.bind(this)
    document.addEventListener("keydown", this.onKeydown)
    this.close()
  }

  disconnect() {
    document.removeEventListener("keydown", this.onKeydown)
  }

  toggle() {
    this.expanded ? this.close() : this.open()
  }

  open() {
    this.panelTarget.hidden = false
    this.sync(true)
  }

  close() {
    this.panelTarget.hidden = true
    this.sync(false)
  }

  // Escape closes from anywhere on the page, not only while focus sits inside
  // the nav — which is what a keyboard user expects from a disclosure.
  onKeydown(event) {
    if (event.key !== "Escape" || !this.expanded) return

    this.close()
    if (this.hasButtonTarget) this.buttonTarget.focus()
  }

  // A link inside the panel navigates; leave it closed for the next page.
  closeOnNavigate() {
    this.close()
  }

  sync(open) {
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", String(open))
      this.buttonTarget.setAttribute("aria-label", open ? this.closeLabelValue : this.openLabelValue)
    }
    if (this.hasIconOpenTarget) this.setHidden(this.iconOpenTarget, open)
    if (this.hasIconCloseTarget) this.setHidden(this.iconCloseTarget, !open)
  }

  // `hidden` is an HTMLElement property; assigning it on an <svg> silently does
  // nothing. Go through the attribute so it works for both.
  setHidden(element, hidden) {
    if (hidden) {
      element.setAttribute("hidden", "")
    } else {
      element.removeAttribute("hidden")
    }
  }

  get expanded() {
    return this.hasPanelTarget && !this.panelTarget.hidden
  }
}
