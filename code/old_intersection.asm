    ; Branchless ray/bounding box intersection:
    ;   (https://tavianator.com/2022/ray_box_boundary.html)
    ;
    ; tmin/tmax will describe the distance along the ray
    ; which intersects the box. We will shrink the distance
    ; between these by clipping them with each plane of the
    ; box.
    ;
    ; At the start, tmin=0 and tmax=infinity. If tmin > tmax
    ; after clipping, the ray does not intersect.
    movaps  xmm0, xmm11         ; calculate inverse of ray direction
    movaps  xmm10, dqword [v4_one]
    divps   xmm10, xmm0         ; xmm10 = 1.0 / dir. apparently, the divide by
                                ; 0 (=infinity) still works here
    xorps   xmm9, xmm9          ; xmm9: tmin = 0.0
    movss   xmm8, [v4_inf]      ; xmm8: tmax = infinity
    movaps  xmm7, dqword [v4_boxmin] ; xmm7: boxmin
    movaps  xmm6, dqword [v4_boxmax] ; xmm6: boxmax

macro clip_ray dim {
    ; available registers: xmm0-xmm5
    ; t1 = (bmin[d] - origin[d]) * dir_inv[d]
    extractps esi, xmm7, dim
    extractps ecx, xmm15, dim
    extractps edx, xmm10, dim
    movd    xmm0, esi           ; xmm0: bmin[d]
    movd    xmm1, ecx           ; xmm1: origin[d]
    movd    xmm2, edx           ; xmm2: dir inverse[d]
    subss   xmm0, xmm1          ; xmm0: bmin[d] - origin[d]
    mulss   xmm0, xmm2
    movss   xmm3, xmm0          ; xmm3: t1

    ; t2 = (bmin[d] - origin[d]) * dir_inv[d]
    extractps esi, xmm6, dim
    movd    xmm0, esi           ; xmm0: bmax[d]
    subss   xmm0, xmm1          ; xmm0: bmin[d] - origin[d]
    mulss   xmm0, xmm2          ; xmm0: t2

    ; available registers: xmm1, xmm2, xmm4, xmm5
    ; tmin = max(tmin, min(min(t1, t2), tmax))
    movss   xmm5, xmm3          ; xmm5: t1
    minss   xmm5, xmm0          ; xmm5: min(t1, t2)
    movss   xmm1, xmm8          ; xmm1: tmax
    minss   xmm1, xmm5          ; xmm1: min(min(t1, t2), tmax)
    maxss   xmm9, xmm1          ; xmm9: updated tmin
    ; tmax = min(tmax, max(max(t1, t2), tmin))
    movss   xmm5, xmm3          ; xmm5: t1
    maxss   xmm5, xmm0          ; xmm5: max(t1, t2)
    movss   xmm1, xmm9          ; xmm1: tmin
    maxss   xmm1, xmm5          ; xmm1: max(max(t1, t2), tmin)
    minss   xmm8, xmm1          ; xmm8: updated tmax
}
    clip_ray 0
    clip_ray 1
    clip_ray 2

;andps   xmm11, dqword [abs_mask] ; xmm11: absolute value for color
;mulps   xmm11, dqword [v4_255] ; xmm11 scaled by 255 for rgb space
ucomiss xmm0, xmm8
jb intersect




; also this old comment for when we were going to do this
    ; OLDTODO: We are going to try adapting the ray/box
    ; intersection algorithm in section 5 of the following
    ; paper:
    ;   (https://jcgt.org/published/0007/03/04/paper-lowres.pdf)
    ;
    ; We won't need to reorient the ray or determine the
    ; winding, as the box is axis aligned and we won't cull
    ; any faces because it is transparent.
