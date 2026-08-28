import { Controller } from "@hotwired/stimulus"

// Toggles between the light and dark palettes.
//
// The initial value is applied by an inline script in the layout head, before
// first paint, so the page never flashes the wrong theme. This controller only
// handles the switch afterwards and keeps the button's label in sync.
//
// Turbo keeps the <html> element across navigations, so the theme survives page
// changes without any extra work here.
export default class extends Controller {
  static targets = ["label", "iconLight", "iconDark"]

  connect() {
    this.render()
  }

  toggle() {
    const next = this.current === "dark" ? "light" : "dark"

    document.documentElement.dataset.theme = next

    try {
      localStorage.setItem("theme", next)
    } catch {
      // Private mode or blocked storage: the theme still applies for this page.
    }

    this.render()
  }

  render() {
    const dark = this.current === "dark"

    this.element.setAttribute("aria-pressed", String(dark))
    this.element.setAttribute(
      "aria-label",
      dark ? "Switch to light theme" : "Switch to dark theme"
    )

    if (this.hasLabelTarget) {
      this.labelTarget.textContent = dark ? "Dark" : "Light"
    }
    if (this.hasIconLightTarget) {
      this.iconLightTarget.hidden = dark
    }
    if (this.hasIconDarkTarget) {
      this.iconDarkTarget.hidden = !dark
    }
  }

  get current() {
    const stamped = document.documentElement.dataset.theme
    if (stamped === "dark" || stamped === "light") return stamped

    return window.matchMedia("(prefers-color-scheme: dark)").matches
      ? "dark"
      : "light"
  }
}
