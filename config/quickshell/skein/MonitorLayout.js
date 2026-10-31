.pragma library

// Edge-snapping math for the monitor arrangement editor. Rects are {name, x, y, w, h} in logical pixels.
function logicalRects(displays) {
  return displays.map(function (d) {
    var s = d.scale > 0 ? d.scale : 1
    return {
      name: d.name,
      x: d.x,
      y: d.y,
      w: Math.round(d.width / s),
      h: Math.round(d.height / s)
    }
  })
}

function overlaps(a, b) {
  return a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h
}

function clamp(v, lo, hi) {
  return Math.max(lo, Math.min(hi, v))
}

// Free offset along a shared edge, aligned to the neighbour's start or center when close
function slide(raw, size, start, length, threshold) {
  var best = clamp(raw, start - size + 1, start + length - 1)
  var targets = [start, start + (length - size) / 2, start + length - size]
  var bestDist = threshold
  for (var i = 0; i < targets.length; i++) {
    var d = Math.abs(raw - targets[i])
    if (d <= bestDist) {
      bestDist = d
      best = targets[i]
    }
  }
  return clamp(Math.round(best), start - size + 1, start + length - 1)
}

// Nearest position to (rawX, rawY) that touches another monitor without overlapping any
function snap(rects, name, rawX, rawY, threshold) {
  var me = rects.find(function (r) { return r.name === name })
  var others = rects.filter(function (r) { return r.name !== name })
  if (!me || others.length === 0) return { x: me ? me.x : 0, y: me ? me.y : 0 }

  var best = null
  var bestDist = Infinity
  others.forEach(function (o) {
    var cands = [
      { x: o.x + o.w, y: slide(rawY, me.h, o.y, o.h, threshold) },
      { x: o.x - me.w, y: slide(rawY, me.h, o.y, o.h, threshold) },
      { x: slide(rawX, me.w, o.x, o.w, threshold), y: o.y + o.h },
      { x: slide(rawX, me.w, o.x, o.w, threshold), y: o.y - me.h }
    ]
    cands.forEach(function (c) {
      var box = { x: c.x, y: c.y, w: me.w, h: me.h }
      if (others.some(function (r) { return overlaps(box, r) })) return
      var dist = Math.hypot(c.x - rawX, c.y - rawY)
      if (dist < bestDist) {
        bestDist = dist
        best = c
      }
    })
  })
  return best || { x: me.x, y: me.y }
}

function placements(rects, name, pos) {
  return rects.map(function (r) {
    return r.name === name ? { name: r.name, x: pos.x, y: pos.y } : { name: r.name, x: r.x, y: r.y }
  })
}
