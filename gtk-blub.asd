;;;; gtk-blub.asd

(asdf:defsystem #:gtk-blub
  :serial t
  :description "Describe gtk-blub here"
  :author "Your Name <your.name@example.com>"
  :license "Specify license here"
  :depends-on (#:cl-cffi-gtk)
  :components ((:file "package")
               (:file "gtk-blub")))

