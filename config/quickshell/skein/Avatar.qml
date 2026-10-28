import QtQuick
import QtQuick.Effects

// Round user picture from ~/.face, or the first letter of the name on the accent colour.
Item {
  id: root

  property string name: ""
  property string source: "" // file path, empty for the initial
  property int revision: 0 // bump to reload the same path

  width: 64
  height: 64

  // A new picture at the same path: drop the cached image and load it again
  onRevisionChanged: {
    const path = photo.source;
    photo.source = "";
    photo.source = path;
  }

  Rectangle {
    id: mask

    anchors.fill: parent
    radius: width / 2
    visible: false
    layer.enabled: true
  }

  Rectangle {
    anchors.fill: parent
    radius: width / 2
    color: Qt.alpha(Skein.accent, 0.8)
    visible: photo.status !== Image.Ready

    Text {
      anchors.centerIn: parent
      text: root.name.charAt(0).toUpperCase()
      color: Skein.background
      font.family: Skein.fontFamily
      font.pointSize: root.height * 0.32
      font.bold: true
    }
  }

  Image {
    id: photo

    anchors.fill: parent
    source: root.source ? `file://${root.source}` : ""
    sourceSize: Qt.size(256, 256)
    fillMode: Image.PreserveAspectCrop
    cache: false
    smooth: true
    visible: status === Image.Ready
    layer.enabled: true
    layer.effect: MultiEffect {
      maskEnabled: true
      maskSource: mask
    }
  }
}
