import QtQuick

// A label with a read-only value on the right.
SettingsRow {
  id: row

  property string value: ""
  property int valueWidth: Math.round(380 * Skein.textScale)

  Text {
    width: row.valueWidth
    horizontalAlignment: Text.AlignRight
    wrapMode: Text.WordWrap
    text: row.value
    textFormat: Text.PlainText
    color: Qt.alpha(Skein.foreground, 0.8)
    font.family: Skein.fontFamily
    font.pointSize: Skein.fontSize - 0.5
  }
}
