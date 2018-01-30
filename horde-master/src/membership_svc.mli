
module Lwt_ZSock = Lwt_zmq.Socket
module Member = Horde_common.Membership.Member
module State = Horde_common.Membership.State
module Group = Horde_common.Membership.Group
                 
(** Thread Safe version of Horde_common.Membership.State *)                     
module SafeState : sig
  type t = {state: State.t; mu: Lwt_mutex.t}
         
  val join_group: t -> string -> Member.t -> t Lwt.t
  val leave_group: t -> string -> Member.t -> t Lwt.t

  val merge: t -> State.t -> t Lwt.t 
  val zero: t 
              
  val view_group: t -> string -> Group.t Lwt.t                              
  val list_groups: t -> (string list) Lwt.t

  val of_state: State.t -> t
  val to_state: t -> State.t
                       
end                                     
                

(** 
  The Server Module works by binding a PUB and Rep socket, 
  A client looking for membership data first obtains it calling view_group on the server's Rep address 
  Then it will subscribe to the GID topic on it's Pub address. 
  
  Joins and Leaves of groups would be handled on the Rep Socket, then the information would be published on the PUB socket. 
  The view_all rpc along with the fact that States are mergeable and serializable are preliminaries for future plans, to make the membership service clusterable. 
 
*)                
module Server : sig
  
  (** type t holds membership state, and it's publish and rep socks*)
  type t = {rep: [`Rep] Lwt_ZSock.t; pub: [`Pub] Lwt_ZSock.t; state: SafeState.t}

  val make: ?state:SafeState.t -> string -> string -> t                                                  
  val join_group: t -> string -> Member.t -> unit Lwt.t
  val view_group: t -> string -> unit Lwt.t
                                      
  (* val ping: t -> unit Lwt.t *)
                                      
  val leave_group: t -> string -> Member.t -> unit Lwt.t
  val list_groups: t -> unit Lwt.t

  val state: t -> SafeState.t
  val rep_s: t -> [`Rep] Lwt_ZSock.t
  val pub_s: t -> [`Pub] Lwt_ZSock.t
                    
end


                  
