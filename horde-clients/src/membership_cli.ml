open Lwt.Infix
       
module Common = Horde_common
module Lwt_ZSock = Common.ZMQ_helpers.Lwt_ZSock
                     
module TMSG = Common.Membership.TMSG
module RMSG = Common.Membership.RMSG 
  
module Member = Common.Membership.Member
module Group = Common.Membership.Group

module ZMQ_Helpers = Common.ZMQ_helpers
module ZSock = ZMQ_Helpers.ZSock
                
type t = {req: [`Req] Lwt_ZSock.t; sub: [`Sub] Lwt_ZSock;}
type sub_cb = TMSG.t Lwt.t -> unit Lwt.t

let make raddr saddr =
  let req_s = ZMQ_Helpers.make_req raddr in
  let sub_s = ZMQ_Helpers.make_sub saddr in
  {req = req_s; sub= sub_s}

let rec handle_sub sub_s cb =
  LwtZSock.recv sub_s >>= fun gid ->
  LwtZSock.recv sub_s >>= fun data ->
  let msg_o = TMSG.of_string data in
  match msg_o with
  | Some x ->
     cb x >>= fun () -> handle_sub sub_s cb
  | None x ->
     Lwt.fail_with "Unable to unmarshal message" >>= fun e ->
     handle_sub sub_s cb 

                
let watch_group t gid cb =
  let sub_s = t.sub in
  let sub_z = Lwt_ZSock.to_socket sub_s in
  ZSock.subscribe sub_z gid;
  handle_sub (Lwt_ZSock.to_socket sub_z) cb

let send_req req_s m =
  let data = TMSG.to_string m in
  Lwt_ZSock.send req_s data 

let recv_rep req_s =
  Lwt_ZSock.recv req_s >>= fun data ->
  RMSG.of_string data

                 
let fail_filter rep_opt =
  match rep_opt with
  | Some x when x.success = true ->
     x
  | Some x when x.success = false ->
     Lwt.fail_with "operation was not successful"
  | None -> "failure to decode RMSG"
                 


let send_and_recv req_s msg =
  send_req req_s msg >>= fun () ->
  recv_req req_s >>= fun rep_o ->
  fail_filter rep_o 

              
let join_group t gid m =
  let open TMSG in
  let msg = Join (gid, m) in
  send_and_recv t.req msg >>= fun rep ->
  Lwt.return_unit
    
let leave_group t gid m =
  let open TMSG in
  let msg = Leave (gid, m) in
  send_and_recv t.req >>= fun rep ->
  Lwt.return_unit
    
let view_group t gid =
  let open TMSG in
  let msg = ViewGroup gid in
  send_and_recv t.req msg >>= fun rep ->
  Lwt.return (Group.of_string rep.data)

let list_groups t =
  let open TMSG in
  let msg = ListGroups in
  send_and_recv t.req msg >>= fun rep ->
  let result = Common.Misc.decode_string_list rep.data in
  Lwt.return result 
  
