import QtQuick

// A label with its current value and a pencil button. The pencil opens a text field with Save and Cancel
// (Enter saves, Escape cancels); accepted(text) fires with the new value.
SettingsRow {
  id: root

  property string value: ""
  property string placeholder: ""
  property bool editing: false

  signal accepted(string text)

  function startEditing(): void {
    field.text = value;
    editing = true;
    field.forceActiveFocus();
    field.selectAll();
  }

  function save(): void {
    const text = field.text.trim();
    editing = false;
    if (text !== "" && text !== value) {
      accepted(text);
    }
  }

  Row {
    spacing: 8

    // Reading: the value and a pencil
    Text {
      visible: !root.editing
      anchors.verticalCenter: parent.verticalCenter
      text: root.value
      color: Qt.alpha(Skein.foreground, 0.85)
      font.family: Skein.fontFamily
      font.pointSize: Skein.fontSize - 0.5
    }

    SmallButton {
      visible: !root.editing
      text: Skein.glyph(0xf03eb)
      onClicked: root.startEditing()
    }

    // Editing: a text field, Save and Cancel
    Rectangle {
      visible: root.editing
      anchors.verticalCenter: parent.verticalCenter
      width: Math.round(200 * Skein.textScale)
      height: Math.round(26 * Skein.textScale)
      radius: 6
      color: Qt.alpha(Skein.foreground, 0.06)
      border.width: 1
      border.color: Skein.accent

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
        onAccepted: root.save()
        Keys.onEscapePressed: root.editing = false

        Text {
          visible: field.text === ""
          anchors.verticalCenter: parent.verticalCenter
          text: root.placeholder
          color: Qt.alpha(Skein.foreground, 0.4)
          font: field.font
        }
      }
    }

    SmallButton {
      visible: root.editing
      text: "Save"
      highlighted: true
      onClicked: root.save()
    }

    SmallButton {
      visible: root.editing
      text: "Cancel"
      onClicked: root.editing = false
    }
  }
}
