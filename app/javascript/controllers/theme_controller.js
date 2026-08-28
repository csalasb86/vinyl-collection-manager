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
  // The wording comes from the view: a controller cannot reach I18n.
  static targets = ["label", "iconLight", "iconDark"]
  static values = {
    lightLabel: { type: String, default: "Light" },
    darkLabel: { type: String, default: "Dark" },
    toLightLabel: { type: String, default: "Switch to light theme" },
    toDarkLabel: { type: String, default: "Switch to dark theme" }
  }

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
      dark ? this.toLightLabelValue : this.toDarkLabelValue
    )

    if (this.hasLabelTarget) {
      this.labelTarget.textContent = dark ? this.darkLabelValue : this.lightLabelValue
    }
    if (this.hasIconLightTarget) this.setHidden(this.iconLightTarget, dark)
    if (this.hasIconDarkTarget) this.setHidden(this.iconDarkTarget, !dark)
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

  get current() {
    const stamped = document.documentElement.dataset.theme
    if (stamped === "dark" || stamped === "light") return stamped

    return window.matchMedia("(prefers-color-scheme: dark)").matches
      ? "dark"
      : "light"
  }
}
