;;;; package.lisp

(defpackage #:gtk-blub
  (:use :gtk :gdk :gobject :glib :pango :cairo :cffi :iterate :common-lisp)
  (:export #:demo-cairo-clock))
