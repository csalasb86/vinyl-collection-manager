import { Controller } from "@hotwired/stimulus"

// Submits the form it is attached to, so filtering needs no Apply click.
//
// Typing is debounced; a select changes once and submits straight away. The
// form still has a real submit button, so this only removes a click rather
// than being the only way to filter.
export default class extends Controller {
  static values = { delay: { type: Number, default: 300 } }

  disconnect() {
    clearTimeout(this.timeout)
  }

  // For text input: wait until typing stops.
  debounced() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.submit(), this.delayValue)
  }

  // For selects: the choice is already deliberate.
  now() {
    clearTimeout(this.timeout)
    this.submit()
  }

  submit() {
    // Page 1 again — the current page rarely exists in the new result set.
    const page = this.element.querySelector("input[name='page']")
    if (page) page.remove()

    // A GET form submits every field, so unset filters would land in the URL
    // as ?year=&genre=&format=. Disabled fields are left out; they go back to
    // enabled once the request is away.
    const blanks = Array.from(this.element.elements).filter(
      (field) => field.name && !field.disabled && field.value === ""
    )
    const restore = () => blanks.forEach((field) => (field.disabled = false))

    blanks.forEach((field) => (field.disabled = true))
    this.element.addEventListener("turbo:submit-end", restore, { once: true })
    setTimeout(restore, 1000) // in case the event never arrives

    this.element.requestSubmit()
  }
}
