
module ZSock = ZMQ.Socket
module Lwt_ZSock = Lwt_zmq.Socket
module ZMQ_Helpers = Horde_common.Zmq_helpers                     

module State = Horde_common.Membership.State
module Group = Horde_common.Membership.Group

module SafeState (S: State): SafeState = struct
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
    State.merge t r;
    Lwt_mutex.unlock t.mu;
    Lwt.return t 
    
                   
  let of_state s =
    {state = s; mu = Lwt_mutex.create ()}

  let to_state t =
    t.state   
end 
                       
module Server = struct
  open Lwt.Infix 
  type t = {rep: Lwt_ZSock.t; sub: Lwt_ZSock.t; state: State.t}

  let make ?state:(state = SafeState.zero) rep_addr pub_addr =
    let rep_s = ZMQ_Helpers.make_rep rep_addr in 
    let pub_s = ZMQ_Helpers.make_pub pub_addr in 
    {rep = rep_s; sub = sub_s; state: state}        
      
  let join_group t gid m =
    SafeState.join_group t.state gid >>= fun x ->
    let pub_body = Member.to_string m in
    
    
end 
