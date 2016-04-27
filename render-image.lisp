;;;; -*- Mode: Lisp; indent-tabs-mode: nil -*-
;;;; ==========================================================================
;;;; render-image.lisp --- Render a png image into a texture
;;;;
;;;; Copyright (c) 2016, Nikhil Shetty <nikhil.j.shetty@gmail.com>
;;;;   All rights reserved.
;;;;
;;;; Redistribution and use in source and binary forms, with or without
;;;; modification, are permitted provided that the following conditions
;;;; are met:
;;;;
;;;;  o Redistributions of source code must retain the above copyright
;;;;    notice, this list of conditions and the following disclaimer.
;;;;  o Redistributions in binary form must reproduce the above copyright
;;;;    notice, this list of conditions and the following disclaimer in the
;;;;    documentation and/or other materials provided with the distribution.
;;;;  o Neither the name of the author nor the names of the contributors may
;;;;    be used to endorse or promote products derived from this software
;;;;    without specific prior written permission.
;;;;
;;;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
;;;; "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
;;;; LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
;;;; A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
;;;; OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
;;;; SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
;;;; LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
;;;; DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
;;;; THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
;;;; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
;;;; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;;;; ==========================================================================

(in-package :vuenix)

(defparameter *count* 0.0)
(defparameter *texture* nil)
(defparameter *v-stream* nil)

(defun-g tex-vert ((vert g-pt))
  (values (v! (pos vert) 1)
          (:smooth (tex vert))))

(defun-g tex-frag ((tex-coord :vec2) &uniform (texture :sampler-2d)
                   (count :float) (pos-offset :vec4))
  (texture texture tex-coord))

(defpipeline ripple-with-wobble () (g-> #'tex-vert #'tex-frag))

(defun step-demo ()
  (step-host)
  (update-repl-link)
  (clear)
  (map-g #'ripple-with-wobble *v-stream*
	 :texture *texture* :count *count* :pos-offset (v! 0 0 0 0))
  (incf *count* 0.08)
  (swap))

(let ((running nil))
  (defun run-loop ()
    (setf running t)
    (let* ((img-data (loop :for i :below 64 :collect
                        (loop :for j :below 64 :collect (random 254)))))
      (setf *v-stream*
            (make-buffer-stream
             (make-gpu-array `((,(v! -0.5 -0.5 0) ,(v!  0  1))
                               (,(v!  0.5 -0.5 0) ,(v!  1  1))
                               (,(v! -0.5  0.5 0) ,(v!  0  0))
                               (,(v!  0.5  0.5 0) ,(v!  1  0))
                               (,(v! -0.5  0.5 0) ,(v!  0  0))
                               (,(v!  0.5 -0.5 0) ,(v!  1  1)))
                             :dimensions 6 :element-type 'g-pt)
             :retain-arrays t))
      (setf *texture* (cepl.devil:load-image-to-texture
                       (merge-pathnames "brick/col.png" *examples-dir*))
            )
      (loop :while (and running (not (shutting-down-p))) :do
	 (continuable (step-demo)))))
  (defun stop-loop () (setf running nil)))
