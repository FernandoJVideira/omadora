import QtQuick

// A clickable list row: leading glyph, label, optional trailing text.
Rectangle {
  id: root

  property string glyph: ""
  property string text: ""
  property string trailing: ""
  property bool highlighted: false
  property bool dimmed: false

  signal clicked

  width: parent ? parent.width : 0
  height: 32
  color: mouse.containsMouse ? Qt.alpha(Skein.foreground, 0.08) : "transparent"

  Behavior on color {
    ColorAnimation {
      duration: 100
    }
  }
  radius: Skein.radiusInner

  Row {
    anchors.fill: parent
    anchors.leftMargin: 6
    anchors.rightMargin: 6
    spacing: 8

    Text {
      anchors.verticalCenter: parent.verticalCenter
      width: 18
      text: root.glyph
      color: root.highlighted ? Skein.accent : Skein.foreground
      font.family: Skein.fontFamily
      font.pointSize: Skein.fontSize
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - 18 - 8 - (trail.visible ? trail.implicitWidth + 8 : 0)
      elide: Text.ElideRight
      text: root.text
      textFormat: Text.PlainText
      opacity: root.dimmed ? 0.5 : 1
      color: root.highlighted ? Skein.accent : Skein.foreground
      font.family: Skein.fontFamily
      font.pointSize: Skein.fontSize
    }

    Text {
      id: trail

      visible: root.trailing !== ""
      anchors.verticalCenter: parent.verticalCenter
      text: root.trailing
      color: Qt.alpha(Skein.foreground, 0.6)
      font.family: Skein.fontFamily
      font.pointSize: Skein.fontSize - 1
    }
  }

  MouseArea {
    id: mouse

    anchors.fill: parent
    hoverEnabled: true
    onClicked: root.clicked()
  }
}
