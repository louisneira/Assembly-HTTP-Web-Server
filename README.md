# Assembly-HTTP-Web-Server
Simple web server written in Assembly (x64) to process GET and POST requests

This repository contains a multithreaded web server for processing HTTP GET and POST requests written in Intel x86 Assembly Language. GET requests with a provided file name will receive the requested file. POST requests will write provided content provided in the HTTP request to the file name provided within the same request.

For execution, the assembly file can be assembled and linked as follows:

as -o my_server_file.o my_server_file.s && ld -o my_server_file my_server_file.o
