format ELF64

;=========================
section '.text' executable
;=========================

; When linking with gl3w, we ge an undefined reference to
; __dso_handle. This shit is a little too esoteric for my
; paygrade, but defining it here like this seems to work.
public __dso_handle
__dso_handle:
	dd 0

; glfw
extrn glfwInit
extrn glfwCreateWindow
extrn glfwWindowHint
extrn glfwMakeContextCurrent
extrn glfwWindowShouldClose
extrn glfwSwapBuffers
extrn glfwPollEvents
extrn glfwTerminate
; gl
extrn glClearColor
extrn glClear
extrn glGenTextures
extrn glBindTexture
extrn glTexParameteri
extrn glTexImage2D
extrn glGenVertexArrays
extrn glBindVertexArray
extrn glGenBuffers
extrn glBindBuffer
extrn glVertexAttribPointer
extrn glEnableVertexAttribArray
extrn glBufferData
extrn glCreateProgram
extrn glAttachShader
extrn glLinkProgram
extrn glDeleteShader
extrn glCreateShader
extrn glShaderSource
extrn glCompileShader
extrn glGetShaderiv
extrn glGetShaderInfoLog
; gl3w
extrn gl3wInit
extrn gl3wIsSupported

public _start
_start:
	; Initialize glfw
	call    glfwInit
	cmp     rax, 1
	jne     error

	mov     rsi, 3
	mov     rdi, 0x00022002 ; GLFW_CONTEXT_VERSION_MAJOR
	call    glfwWindowHint
	mov     rsi, 3
	mov     rdi, 0x00022003 ; GLFW_CONTEXT_VERSION_MINOR
	call    glfwWindowHint
	mov     rsi, 0x00022008 ; GLFW_OPENGL_CORE_PROFILE
	mov     rdi, 0x00032001 ; GLFW_OPENGL_PROFILE
	call    glfwWindowHint

	mov     r8, 0
	mov     rcx, 0
	mov     rdx, window_name
	mov     rsi, 480
	mov     rdi, 640
	call    glfwCreateWindow

	mov     [glfw_window], rax
	cmp     [glfw_window], 0
	je      error
	mov     rdi, [glfw_window]
	call    glfwMakeContextCurrent

	; Initialize gl3w
	call    gl3wInit
	cmp     rax, 0
	jne     error

	mov     rsi, 3
	mov     rdi, 3
	call    gl3wIsSupported
	cmp     rax, 1
	jne     error

	; Initialize OpenGL. We will need a texture and a quad to
	; render across the screen as well as a shader program

	; Screen texture
	mov     rsi, gl_texture
	mov     rdi, 1
	call    glGenTextures

	mov     esi, [gl_texture]
	mov     rdi, 0x0DE1 ; GL_TEXTURE_2D
	call    glBindTexture

	mov     rdx, 0x812F ; GL_CLAMP_TO_EDGE
	mov     rsi, 0x2802 ; GL_TEXTURE_WRAP_S
	mov     rdi, 0x0DE1 ; 0x0DE1 ; GL_TEXTURE_2D
	call    glTexParameteri
	mov     rdx, 0x812F ; GL_CLAMP_TO_EDGE
	mov     rsi, 0x2803 ; GL_TEXTURE_WRAP_T
	mov     rdi, 0x0DE1 ; 0x0DE1 ; GL_TEXTURE_2D
	call    glTexParameteri
	mov     rdx, 0x2600 ; GL_NEAREST
	mov     rsi, 0x2801 ; GL_TEXTURE_MIN_FILTER
	mov     rdi, 0x0DE1 ; GL_TEXTURE_2D
	call    glTexParameteri
	mov     rdx, 0x2600 ; GL_NEAREST
	mov     rsi, 0x2800 ; GL_TEXTURE_MAG_FILTER
	mov     rdi, 0x0DE1 ; GL_TEXTURE_2D
	call    glTexParameteri

	;sub     rsp, 32
	;mov     qword [rsp + 0x20], screen
	;mov     [rsp + 0x18], dword 0x1401 ; GL_UNSIGNED_BYTE
	;mov     [rsp + 0x10], dword 0x1908 ; GL_RGBA
	push    0
	push    screen
	push    0x1401
	push    0x1908
	mov     r9, 0
	mov     r8d, [logical_h]
	mov     ecx, [logical_w]
	mov     rdx, 0x1908 ; GL_RGBA
	mov     rsi, 0
	mov     rdi, 0x0DE1 ; GL_TEXTURE_2D
	call    glTexImage2D
	add     rsp, 32

	; Quad mesh
	mov     rsi, gl_vbo
	mov     rdi, 1
	call    glGenVertexArrays

	mov     edi, [gl_vbo]
	call    glBindVertexArray

	mov     rsi, gl_vbo
	mov     rdi, 1
	call    glGenBuffers
	mov     r12, rax

	mov     rsi, 0x8892 ; GL_ARRAY_BUFFER
	mov     rdi, r12
	call    glBindBuffer

	mov     rcx, 0x88E4 ; GL_STATIC_DRAW
	mov     rdx, verts
	mov     esi, [verts_len]
	mov     rdi, 0x8892 ; GL_ARRAY_BUFFER
	call    glBufferData

	mov     rdi, 0
	call    glEnableVertexAttribArray

	mov     r9, 0
	mov     r8, 8
	mov     rcx, 0
	mov     rdx, 0x1406 ; GL_FLOAT
	mov     rsi, 2
	mov     rdi, 0
	call    glVertexAttribPointer

	; Shader program
	call    glCreateProgram
	mov     r12, rax ; program id

	mov     rcx, r12
	mov     rdx, vert_src_ptr
	mov     rsi, vert_src_len
	mov     rdi, 0x8B31 ; GL_VERTEX_SHADER
	call    compile_shader
	mov     r13, rax ; vert shader id

	mov     rcx, r12
	mov     rdx, frag_src_ptr
	mov     rsi, frag_src_len
	mov     rdi, 0x8B30 ; GL_FRAGMENT_SHADER
	call    compile_shader
	mov     r14, rax ; frag shader id

	mov     rdi, r12
	call    glLinkProgram

	mov     rdi, r13
	call    glDeleteShader
	mov     rdi, r14
	call    glDeleteShader
	; r13, r14 are free for use

; This runs repeatedly until the program wants to exit
main_loop:
	mov     rdi, [glfw_window]
	call    glfwWindowShouldClose
	cmp     rax, 1
	je      exit

	movss   xmm3, [clear_a]
	movss   xmm2, [clear_b]
	movss   xmm1, [clear_g]
	movss   xmm0, [clear_r]
	call    glClearColor
	mov     rdi, 0x00004000 ; GL_COLOR_BUFFER_BIT
	call    glClear

	mov     rdi, [glfw_window]
	call    glfwSwapBuffers
	call    glfwPollEvents
	jmp     main_loop

; TODO: Implement error messages
error:
	jmp     exit

exit:
	call    glfwTerminate
	mov     rax, 60 ; exit
	xor     rdi, rdi
    syscall 

; Compiles a shader for OpenGL
;
; input
;   rcx: program id
;   rdx: src address ptr
;   rsi: src len address
;   rdi: type
; output
;   rax: shader id
compile_shader:
	sub     rsp, 40
	mov     [rsp+0x00], rsi ; src len address
	mov     [rsp+0x08], rdx ; src address ptr
	mov     [rsp+0x10], rcx ; program id

	call    glCreateShader ; type already in rdi
	mov     [rsp+0x18], rax ; shader id

	mov     rcx, [rsp+0x00]
	mov     rdx, [rsp+0x08]
	mov     rsi, 1
	mov     rdi, [rsp+0x18]
	call    glShaderSource

	mov     rdi, [rsp+0x18]
	call    glCompileShader

	lea     rdx, [rsp+0x20] ; compilation success flag
	mov     rsi, 0x8B81 ; GL_COMPILE_STATUS
	mov     rdi, [rsp+0x18]
	call    glGetShaderiv

	cmp     qword [rsp+0x20], 0
	jne     compile_shader_success

	; Log error if shader compilation failed
	mov     rcx, msg
	mov     rdx, 0
	mov     rsi, 100
	mov     rdi, [rsp+0x18]
	call    glGetShaderInfoLog

	mov     rax, 1 ; write syscall
	mov     rdi, 1 ; stdout
	mov     rsi, msg 
	mov     rdx, msglen 
	syscall

	jmp     exit

compile_shader_success:
	mov     rsi, [rsp+0x18]
	mov     rdi, [rsp+0x10]
	call    glAttachShader

	mov     rax, [rsp+0x18] ; return shader id
	add     rsp, 40
	ret

;========================
section '.data' writeable
;========================

msglen = 4096
msg         rd msglen; general purpose string buffer
window_name db 'Cube Games', 0

; render data
glfw_window  rq 1
gl_texture   rd 1
gl_vbo       rd 1
logical_w    dd 640
logical_h    dd 360
screen       rd 640 * 360
clear_r      dd 0.3
clear_g      dd 0.1
clear_b      dd 0.2
clear_a      dd 1.0
verts        dd 1.0, 1.0, 1.0, -1.0, -1.0, 1.0, 1.0, -1.0, -1.0, -1.0, -1.0, 1.0
verts_len    dd 12

include 'generation/generated_data.asm'
vert_src_ptr dq vert_src
frag_src_ptr dq frag_src
