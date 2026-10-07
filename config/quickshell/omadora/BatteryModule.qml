import QtQuick
import Quickshell.Services.UPower

// Laptop battery; hidden on machines without one.
BarItem {
  readonly property var device: UPower.displayDevice
  readonly property bool present: device !== null && device.isLaptopBattery && device.isPresent
  // Quickshell reports 0-1; older builds reported 0-100
  readonly property int capacity: present ? Math.round(device.percentage > 1 ? device.percentage : device.percentage * 100) : 0
  readonly property int iconIndex: Math.max(0, Math.min(9, Math.floor(capacity / 10)))

  readonly property string status: {
    if (!present) {
      return "";
    }
    switch (device.state) {
    case UPowerDeviceState.Charging:
      return "charging";
    case UPowerDeviceState.FullyCharged:
      return "full";
    case UPowerDeviceState.Discharging:
    case UPowerDeviceState.PendingDischarge:
    case UPowerDeviceState.Empty:
      return "discharging";
    default:
      return UPower.onBattery ? "discharging" : "plugged";
    }
  }

  text: {
    const charging = [0xf089c, 0xf0086, 0xf0087, 0xf0088, 0xf089d, 0xf0089, 0xf089e, 0xf008a, 0xf008b, 0xf0085];
    const discharging = [0xf007a, 0xf007b, 0xf007c, 0xf007d, 0xf007e, 0xf007f, 0xf0080, 0xf0081, 0xf0082, 0xf0079];
    switch (status) {
    case "charging":
      return Omadora.glyph(charging[iconIndex]);
    case "discharging":
      return Omadora.glyph(discharging[iconIndex]);
    case "full":
      return Omadora.glyph(0xf0085);
    case "plugged":
      return Omadora.glyph(0xf1e6);
    default:
      return "";
    }
  }
  tooltip: {
    const watts = Math.abs(device?.changeRate ?? 0).toFixed(0);
    switch (status) {
    case "charging":
      return `${watts}W↑ ${capacity}%`;
    case "discharging":
      return `${watts}W↓ ${capacity}%`;
    default:
      return `${capacity}%`;
    }
  }
  onLeftClicked: Omadora.run("omadora-exec omadora-menu power")
  onRightClicked: Omadora.run('notify-send -u low "$(omactl info battery)"')
}
