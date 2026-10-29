import QtQuick

// Label with a single-line text field. accepted(text) fires on Enter.
SettingsRow {
  id: root

  property alias text: field.text
  property string placeholder: ""

  signal accepted(string text)

  Rectangle {
    width: Math.round(240 * Skein.textScale)
    height: Math.round(26 * Skein.textScale)
    radius: Skein.glass ? 10 : 6
    color: Qt.alpha(Skein.foreground, 0.06)
    border.width: 1
    border.color: field.activeFocus ? Skein.accent : Qt.alpha(Skein.foreground, 0.25)

    TextInput {
      id: field

      anchors.fill: parent
      anchors.leftMargin: 8
      anchors.rightMargin: 8
      verticalAlignment: TextInput.AlignVCenter
      clip: true
      color: Skein.foreground
      selectionColor: Skein.accent
      selectedTextColor: Skein.background
      font.family: Skein.fontFamily
      font.pointSize: Skein.fontSize
      onAccepted: root.accepted(text)

      Text {
        visible: field.text === "" && !field.activeFocus
        anchors.verticalCenter: parent.verticalCenter
        text: root.placeholder
        color: Qt.alpha(Skein.foreground, 0.4)
        font: field.font
      }
    }
  }
}
