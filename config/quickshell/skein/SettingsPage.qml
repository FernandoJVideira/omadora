import QtQuick

// A scrolling settings page: put sections inside, set `backend` from the Settings window.
Flickable {
  id: root

  property var backend: null
  default property alias content: body.data

  contentWidth: width
  contentHeight: body.implicitHeight + 12
  clip: true
  boundsBehavior: Flickable.StopAtBounds

  Column {
    id: body

    width: root.width - 12
    spacing: 6
  }
}
