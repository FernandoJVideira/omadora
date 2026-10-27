.pragma library

// Convert the Pango markup the bar scripts print into Qt rich text.
// Line breaks become <br>, except inside <tt> blocks which keep their
// column alignment as preformatted text.
function toHtml(markup) {
  if (!markup) {
    return "";
  }

  return markup
    .replace(/\r/g, "\n")
    .split(/(<tt>[\s\S]*?<\/tt>)/)
    .map(part => part.startsWith("<tt>")
      ? "<pre>" + part.slice(4, -5) + "</pre>"
      : part.replace(/\n/g, "<br>"))
    .join("");
}
