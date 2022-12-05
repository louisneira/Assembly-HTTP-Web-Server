.intel_syntax noprefix
.globl _start

.section .text

_start:

        mov rdi, 0x2                    # const AF_INET
        mov rsi, 0x1                    # const SOCK_STREAM
        mov rdx, 0x0                    # const IPPROTO_IP
        mov rax, 0x29                   #SYS_socket
        syscall

        mov rdi, 0x3                    # const sockfd
        lea rsi, [rip+sockaddr]         # const struct sockaddr
        mov rdx, 0x10                   # const addrlen
        mov rax, 0x31                   # SYS_bind
        syscall

        mov rdi, 3                      # const sockfd
        mov rsi, 0                      # const backlog
        mov rax, 0x32                   # SYS_listen
        syscall

accept_new_connection:

        mov rdi, 3                      # const sockfd
        mov rsi, 0                      # const addr
        mov rdx, 0                      # const addrlen
        mov rax, 0x2B                   # SYS_accept
        syscall

        mov rax, 0x39                   # SYS_fork
        syscall

        cmp rax, 0
        je process_request

        mov rdi, 4                      # const sockfd
        mov rax, 3                      # SYS_close
        syscall
        jmp accept_new_connection
        
process_request:

        mov rdi, 3                      # const sockfd
        mov rax, 3                      # SYS_close
        syscall

        mov rdi, 4                      # fd
        mov rsi, rsp                    # buf
        mov rdx, 0x200                  # count
        mov rax, 0                      # SYS_read
        syscall

        mov rbx, rsp                    # iterator for file name
        mov rcx, 0                      # current byte
        mov r12, rax                    # size of input read
        mov r9, 0                       # number of bytes scanned

        sub rsp, 0x200

find_start_of_file:

        mov cl, BYTE PTR [rbx]
        cmp cl, 0x20
        je file_name_start_found
        inc rbx
        inc r9
        jmp find_start_of_file

file_name_start_found:

        inc rbx
        inc r9
        mov r11, rbx                    # start position of file name

find_end_of_file:

        mov cl, BYTE PTR [rbx]
        cmp cl, 0x20
        je type_of_request
        inc rbx
        inc r9
        jmp find_end_of_file

type_of_request:

        mov rcx, 0
        mov cl, BYTE PTR [rsi]
        cmp cl, 0x47
        jne process_post_request

process_get_request:

open_file_to_read:

        mov BYTE PTR [rbx], 0
        mov rdi, r11                    # const pathname 
        mov rsi, 0                      # flags
        mov rdx, 0                      # mode
        mov rax, 2                      # SYS_open
        syscall

read_file:

        mov rdi, rax                    # fd
        mov rsi, rsp                    # buf
        mov rdx, 0x200                  # count
        mov rax, 0                      # SYS_read
        syscall

        mov rdi, rdi                    # const sockfd
        mov rax, 3                      # SYS_close
        syscall

write_http_OK_response_get:

        mov rdi, 4                      # const sockfd
        lea rsi, [rip+response]         # const response
        mov rdx, 0x13                   # size of response
        mov rax, 1                      # SYS_write
        mov r9, 0
        syscall

        mov rbx, rsp

find_buffer_size:

        mov cl, BYTE PTR [rbx]
        cmp cl, 0
        je write_response
        inc rbx
        inc r9
        jmp find_buffer_size

write_response:

        mov rdi, 4                      # fd
        mov rsi, rsp                    # const buf
        mov rdx, r9                     # count
        mov rax, 1                      # SYS_WRITE
        syscall

        mov rdi, 4                      # const sockfd
        mov rax, 3                      # SYS_close
        syscall

        jmp done

process_post_request:

open_file_to_write:

        mov BYTE PTR [rbx], 0
        mov rdi, r11                    # const pathname 
        mov rsi, 0x41                   # flags
        mov rdx, 511                    # mode
        mov rax, 2                      # SYS_open
        syscall

        mov r11, rax                    # fd from SYS_open
        inc rbx
        inc r9

find_content:

        mov rcx, 0
        mov ecx, DWORD PTR [rbx]
        cmp ecx, 0x0A0D0A0D
        je write_to_file
        inc rbx
        inc r9
        jmp find_content

write_to_file:

        add rbx, 4
        add r9, 4
        sub r12, r9

        mov rdi, r11                    # fd
        mov rsi, rbx                    # const buf
        mov rdx, r12                    # count
        mov rax, 1                      # SYS_WRITE
        syscall

                                        # rdi already contains correct sockfd
        mov rax, 3                      # SYS_close
        syscall

write_http_response_post:

        mov rdi, 4                      # fd for HTTP connection   
        lea rsi, [rip+response]         # const buf
        mov rdx, 0x13                   # count
        mov rax, 1                      # SYS_WRITE
        syscall

done:

        mov rdi, 0
        mov rax, 0x3C                   # SYS_exit
        syscall

.section .data
sockaddr:

        .2byte 0x2
        .2byte 0x5000
        .4byte 0
        .8byte 0x0

response:
        # HTTP/1.0 200 OK\r\n\r\n
        .byte 0x48
        .byte 0x54
        .byte 0x54
        .byte 0x50
        .byte 0x2F
        .byte 0x31
        .byte 0x2E
        .byte 0x30
        .byte 0x20
        .byte 0x32
        .byte 0x30
        .byte 0x30
        .byte 0x20
        .byte 0x4F
        .byte 0x4B
        .byte 0x0D
        .byte 0x0A
        .byte 0x0D
        .byte 0x0A