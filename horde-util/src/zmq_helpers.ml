module ZSock = ZMQ.Socket
module Lwt_ZSock = Lwt_zmq.Socket
module CTX = ZMQ.Context

let tcp_addr ~host:(host="*") port () =
  Fmt.strf "tcp://%s:%d" host port 

let ipc_addr ~host:(host="*") port () =
  Fmt.strf "ipc://%s:%d" host port
           
let inproc_addr ~host:(host="*") port () =
  Fmt.strf "inproc://%s:%d" host port

           
(*pgm is a multicast protocol you can only use for pub sub*)           
let pgm_addr ~host:(host="*") port () =
  Fmt.strf "pgm://%s:%d" host port


(* epgm is the same as pgm but it's encapsulated onto udp*)
let epgm_addr ~host:(host="*") port () =
  Fmt.strf "epgm://%s:%d" host port

           
let make_pub addr =
  let ctx = CTX.create () in
  let sock = ZSock.create ctx ZSock.pub in
  ZSock.bind sock addr;
  Lwt_ZSock.of_socket sock 


let make_rep addr =
  let ctx = CTX.create () in
  let sock = ZSock.create ctx ZSock.rep in
  ZSock.bind sock addr;
  Lwt_ZSock.of_socket sock 
