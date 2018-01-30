
module ZSock = ZMQ.Socket
module Lwt_ZSock = Lwt_zmq.Socket
module ZMQ_Helpers = Horde_common.Zmq_helpers
                       
open Lwt.Infix
       
module Common = Horde_common 
module State = Horde_common.Membership.State
module Group = Horde_common.Membership.Group
module TMSG = Common.Membership.TMSG
module RMSG = Common.Membership.RMSG
module Member = Common.Membership.Member
                  
                 
module SafeState = struct
  type t = {state: State.t; mu: Lwt_mutex.t}

  let zero = {state = State.zero; mu = ( Lwt_mutex.create () )}
               
  let join_group t gid m =
    Lwt_mutex.lock t.mu >|= fun () ->
    State.join_group t.state gid m;
    Lwt_mutex.unlock t.mu;
    t

  let leave_group t gid m =
    Lwt_mutex.lock t.mu >|= fun () ->
    State.leave_group t.state gid m;
    Lwt_mutex.unlock t.mu;
    t

  let view_group t gid =
    let grp = State.view_group t.state gid in
    Lwt.return grp

  let list_groups t =
    let groups = State.list_groups t.state in
    Lwt.return groups
    

  let merge t r =
    Lwt_mutex.lock t.mu >>= fun () ->
    State.merge t.state r;
    Lwt_mutex.unlock t.mu;
    Lwt.return t 
    
                   
  let of_state s =
    {state = s; mu = Lwt_mutex.create ()}

  let to_state t =
    t.state   
end 
                       
module Server = struct
  open TMSG
  open RMSG
         
    
  type t = {rep: [`Rep] Lwt_ZSock.t; pub: [`Pub] Lwt_ZSock.t; state: SafeState.t}

  let make ?state:(state = SafeState.zero) rep_addr pub_addr =
    let rep_s = ZMQ_Helpers.make_rep rep_addr in 
    let pub_s = ZMQ_Helpers.make_pub pub_addr in 
    {rep = rep_s; pub = pub_s; state = state}        

  let publish s topic data =
    Lwt_ZSock.send ~more:(true) s topic >>= fun () ->
    Lwt_ZSock.send s (TMSG.to_string data)

  let reply s msg =
    Lwt_ZSock.send s (RMSG.to_string msg)
                  
  let join_group t gid m =
    SafeState.join_group t.state gid m >>= fun x ->
    let pub_msg = Join (gid, m) in
    publish t.pub gid pub_msg  >>= fun () ->

    let body = Fmt.strf "%s was added to group %s \n" (Member.to_address m) gid in
    let rmsg = {success = true; data = body;} in
    reply t.rep rmsg

          
  let leave_group t gid m =
    SafeState.leave_group t.state gid m >>= fun x ->
    let pmsg = Leave (gid, m) in
    publish t.pub gid pmsg >>= fun () ->

    let body = Fmt.strf "%s was removed from group %s" (Member.to_address m) gid in
    let rmsg = {success = true; data = body} in
    reply t.rep rmsg 
    

  let list_groups t =
    SafeState.list_groups t.state >>= fun x ->
    let body = Common.Misc.encode_string_list x in
    let msg = {success=true; data=body} in
    reply t.rep msg

  let view_group t gid =
    SafeState.view_group t.state gid >>= fun x ->
    let body = Group.to_string x in
    let msg = {success=true; data=body} in
    reply t.rep msg 

  let state t =
    t.state

  let pub_s t =
    t.pub

  let rep_s t =
    t.rep
    
end 
