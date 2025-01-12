(conflict
   (start) @conflict.start
   (#set! priority 105))

(conflict
  (start
    label: (label) @conflict.start.label
    (#set! priority 105)))

(conflict
  ours: (hunk) @conflict.ours
  (#set! priority 105))

(conflict
  (common_sep) @conflict.common_sep
  (#set! priority 105))

(conflict
  (common_sep
    (label) @conflict.common_sep.label
    (#set! priority 105)))

(conflict
  common: (hunk) @conflict.common
  (#set! priority 105))

(conflict
  (sep) @conflict.sep
  (#set! priority 105))

(conflict
  (sep
    label: (label) @conflict.sep.label
    (#set! priority 105)))

(conflict
  theirs: (hunk) @conflict.theirs
  (#set! priority 105))

(conflict
  (end) @conflict.end
  (#set! priority 105))

(conflict
  (end
    label: (label) @conflict.end.label
    (#set! priority 105)))
