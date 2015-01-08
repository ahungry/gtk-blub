;; Testing out cl-cffi-gtk
;;;; gtk-blub.lisp

(in-package #:gtk-blub)

;;; "gtk-blub" goes here. Hacks and glory await!

;; Lets draw a rect
(defclass blub-rect (gtk-drawing-area)
  ((size :initarg :size
         :initform 10
         :accessor blub-rect-size)
   (x-pos :initarg :x-pos
          :initform 0
          :accessor blub-rect-x-pos)
   (y-pos :initarg :y-pos
          :initform 0
          :accessor blub-rect-y-pos)
   (total :initarg :total
          :initform 1
          :accessor blub-rect-total))
  (:metaclass gobject-class))

(defmethod initialize-instance :after
    ((rect blub-rect) &key &allow-other-keys)
  ;; Timeout to set the size
  (g-timeout-add 100
                 (lambda ()
                   (setf (blub-rect-size rect) 20)
                   (gtk-widget-queue-draw rect)
                   +g-source-continue+))
  ;; Signal handler to draw rect
  (g-signal-connect rect "draw"
                    (lambda (widget cr)
                      (let* ((cr (pointer cr))
                             (window (gtk-widget-window widget))
                             (x (blub-rect-x-pos rect))
                             (y (blub-rect-y-pos rect))
                             (size (blub-rect-size rect))
                             (width (gdk-window-get-width window))
                             (height (gdk-window-get-height window)))
                        ;; Clear
                        (when (> (+ size x) width)
                          (setf (blub-rect-x-pos rect) 0))
                        (when (> (+ size y) height)
                          (setf (blub-rect-y-pos rect) 0))
                        (incf (blub-rect-x-pos rect) 15)
                        (incf (blub-rect-y-pos rect) 15)
                        (cairo-set-source-rgb cr 1.0 0.0 0.5)
                        (cairo-paint cr)
                        (cairo-set-source-rgb cr 0.0 1.0 0.75)
                        (dotimes (i (1+ (blub-rect-total rect)))
                          (cairo-rectangle cr (+ (* 2 size i) x) y size size))
                        (cairo-move-to cr 0 0)
                        (cairo-line-to cr 200 200)
                        (cairo-stroke cr)
                        (cairo-fill-preserve cr)
                        (cairo-set-source-rgb cr 0 0 0)
                        (cairo-stroke cr)
                        (cairo-destroy cr)
                        t))))

(defun demo-blub-rect ()
  (let ((output *standard-output*))
    (within-main-loop
     (let ((window (make-instance 'gtk-window
                                  :title "Blub Rect"
                                  :type :toplevel
                                  :gravity :static
                                  :window-position :center
                                  :default-width 400
                                  :default-height 300))
           (box (make-instance 'gtk-vbox))
           (button (make-instance 'gtk-button :label "Hmmm..."))
           (rect (make-instance 'blub-rect
                                :width-request 400
                                :height-request 280)))
       (g-signal-connect window "destroy"
                         (lambda (widget)
                           (declare (ignore widget))
                           (leave-gtk-main)))
       (g-signal-connect button "clicked"
                         (lambda (b)
                           (declare (ignore b))
                           (format output "Clicked button~%")
                           (incf (blub-rect-total rect) 2)))
       (gtk-window-set-keep-above window t)
       (gtk-container-add window box)
       (gtk-box-pack-start box button)
       (gtk-box-pack-start box rect)
       (gtk-widget-show-all window)))))


;; Grabbed from http://www.crategus.com/books/cl-gtk/gtk-tutorial_16.html
;; Class egg-clock-face is a subclass of a GtkDrawingArea

(defclass egg-clock-face (gtk-drawing-area)
  ((time :initarg :time
         :initform (multiple-value-list (get-decoded-time))
         :accessor egg-clock-face-time))
  (:metaclass gobject-class))

(defmethod initialize-instance :after
    ((clock egg-clock-face) &key &allow-other-keys)
  ;; A timeout source for the time
  (g-timeout-add 1000
                 (lambda ()
                   (setf (egg-clock-face-time clock)
                         (multiple-value-list (get-decoded-time)))
                   (gtk-widget-queue-draw clock)
                   +g-source-continue+))
  ;; Signal handler which draws the clock
  (g-signal-connect clock "draw"
                    (lambda (widget cr)
                      (let ((cr (pointer cr))
                            ;; Get the GdkWindow for the widget
                            (window (gtk-widget-window widget)))
                        ;; Clear surface
                        (cairo-set-source-rgb cr 1.0 1.0 1.0)
                        (cairo-paint cr)
                        (let* ((x (* (gdk-window-get-width window) 2))
                               (y (* (gdk-window-get-height window) 2))
                               (radius (- (min x y) 12)))
                          ;; Clock back
                          (cairo-arc cr x y radius 0 (* 2 pi))
                          (cairo-set-source-rgb cr 1 1 1)
                          (cairo-fill-preserve cr)
                          (cairo-set-source-rgb cr 0 0 0)
                          (cairo-stroke cr)
                          ;; Clock ticks
                          (let ((inset 0.0)
                                (angle 0.0))
                            (dotimes (i 12)
                              (cairo-save cr)
                              (setf angle (* (* i pi) 6))
                              (if (eql 0 (mod i 3))
                                  (setf inset (* 0.2 radius))
                                  (progn
                                    (setf inset (* 0.1 radius))
                                    (cairo-set-line-width cr (* 0.5 (cairo-get-line-width cr)))))
                              (cairo-move-to cr
                                             (+ x (* (- radius inset) (cos angle)))
                                             (+ y (* (- radius inset) (sin angle))))
                              (cairo-line-to cr
                                             (+ x (* radius (cos angle)))
                                             (+ y (* radius (sin angle))))
                              (cairo-stroke cr)
                              (cairo-restore cr)))
                          (let ((seconds (first (egg-clock-face-time clock)))
                                (minutes (second (egg-clock-face-time clock)))
                                (hours (third (egg-clock-face-time clock))))
                            ;; Hour hand: The hour hand is rotated 30 degrees (pi/6 r) per hour
                            ;; + 1/2 a degree (pi/360 r) per minute
                            (let ((hours-angle (* (* pi 6) hours))
                                  (minutes-angle (* (* pi 360) minutes)))
                              (cairo-save cr)
                              (cairo-set-line-width cr (* 2.5 (cairo-get-line-width cr)))
                              (cairo-move-to cr x y)
                              (cairo-line-to cr
                                             (+ x (* (* radius 2)
                                                     (sin (+ hours-angle minutes-angle))))
                                             (+ y (* (* radius 2)
                                                     (- (cos (+ hours-angle minutes-angle))))))
                              (cairo-stroke cr)
                              (cairo-restore cr))
                            ;; Minute hand: The minute hand is rotated 6 degrees (pi/30 r)
                            ;; per minute
                            (let ((angle (* (* pi 30) minutes)))
                              (cairo-move-to cr x y)
                              (cairo-line-to cr
                                             (+ x (* radius 0.75 (sin angle)))
                                             (+ y (* radius 0.75 (- (cos angle)))))
                              (cairo-stroke cr))
                            ;; Seconds hand: Operates identically to the minute hand
                            (let ((angle (* (* pi 30) seconds)))
                              (cairo-save cr)
                              (cairo-set-source-rgb cr 1 0 0)
                              (cairo-move-to cr x y)
                              (cairo-line-to cr (+ x (* radius 0.7 (sin angle)))
                                             (+ y (* radius 0.7 (- (cos angle)))))
                              (cairo-stroke cr)
                              (cairo-restore cr))))
                        ;; Destroy the Cario context
                        (cairo-destroy cr)
                        t))))

(defun demo-cairo-clock ()
  (within-main-loop
   (let ((window (make-instance 'gtk-window
                                :title "Demo Cairo Clock"
                                :default-width 250
                                :default-height 250))
         (clock (make-instance 'egg-clock-face)))
     (g-signal-connect window "destroy"
                       (lambda (widget)
                         (declare (ignore widget))
                         (leave-gtk-main)))
     (gtk-container-add window clock)
     (gtk-widget-show-all window))))
