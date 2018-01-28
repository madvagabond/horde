



(** ADT for contact information*)
module Member : sig
  type t
         
  val to_string: t -> string
  val of_string: string -> t option
  val to_address: t -> string
                         
  val protocol: t -> string
  val port: t -> int
  val host: t -> string
                   
  let compare: t -> t -> int
                           
end


module Group: sig
  type t
         
  val to_string: t -> string
  val of_string: string -> t option
                             
  val leave_group: t -> Member.t -> t
  val join_group: t -> Member.t -> t
                                     
end

(** 
  Holds State for group membership 
  Is a Monoid with the binary operation of merge 
*)                
module State: sig
  type t
  val add_to_group: t -> string -> member -> state
  val leave_group: t -> string -> member

  val merge: t -> t -> t
  val zero: t
              
  val group_membership: t -> string -> Group.t 
  val of_string: string -> t option
                             
  val to_string: t -> string
  val list_groups: t -> string list                       
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
  type t

  val make: ?state: State.t -> string -> string -> t                                                  
  val join_group: t -> string -> Member -> unit Lwt.t
  val view_group: t -> string -> unit Lwt.t
                                      
  val ping: t -> unit Lwt.t
  val leave_group: t -> string -> Member.t -> unit Lwt.t
  val view_all: t -> unit Lwt.t
                                                                                                                                
end


                  
