import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["editable", "hidden"]

  connect() {
    // Conteúdo inicial (se já existir)
    if (this.hiddenTarget.value) {
      this.editableTarget.innerHTML = this.hiddenTarget.value
    }

    // Sincroniza ao digitar
    this._onInput = () => this.sync()
    this.editableTarget.addEventListener("input", this._onInput)

    // Salva seleção sempre que o usuário mexer no editor
    this._saveRange = () => this.saveRange()
    this.editableTarget.addEventListener("keyup", this._saveRange)
    this.editableTarget.addEventListener("mouseup", this._saveRange)
    this.editableTarget.addEventListener("mouseout", this._saveRange)

    // Garante salvar antes de enviar o form
    this.element.closest("form")?.addEventListener("submit", () => this.sync())
  }

  disconnect() {
    this.editableTarget.removeEventListener("input", this._onInput)
    this.editableTarget.removeEventListener("keyup", this._saveRange)
    this.editableTarget.removeEventListener("mouseup", this._saveRange)
    this.editableTarget.removeEventListener("mouseout", this._saveRange)
  }

  // ===== Ações da toolbar =====
  cmd(e) {
    e.preventDefault()
    const cmd = e.currentTarget.dataset.cmd
    this.focusEditable()
    document.execCommand(cmd, false, null)
    this.sync()
  }

  link(e) {
    e.preventDefault()
    this.focusEditable()
    const url = window.prompt("URL do link:")
    if (url) document.execCommand("createLink", false, url)
    this.sync()
  }

  clear(e) {
    e.preventDefault()
    this.editableTarget.innerHTML = ""
    this.sync()
  }

  // ===== Utilidades =====
  sync() {
    this.hiddenTarget.value = this.editableTarget.innerHTML
  }

  focusEditable() {
    this.editableTarget.focus()
    this.restoreRange()
  }

  saveRange() {
    const sel = window.getSelection()
    if (sel && sel.rangeCount > 0) {
      this.range = sel.getRangeAt(0)
    }
  }

  restoreRange() {
    if (!this.range) return
    const sel = window.getSelection()
    sel.removeAllRanges()
    sel.addRange(this.range)
  }
}
