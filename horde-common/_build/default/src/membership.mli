
module BatHashTbl = Batteries.Hashtbl
module BatSet = Batteries.Set
                  
module RMSG : sig
  type t
  val to_string: t -> string 
  val of_string: string -> t option
end
                

(** ADT for contact information*)
module Member : sig
  type t = {protocol: string; host: string; port: int}
         
  val to_string: t -> string
  val of_string: string -> t option
  val to_address: t -> string
                         
  val protocol: t -> string
  val port: t -> int
  val host: t -> string
                   
  val compare: t -> t -> int
                           
end


module Group : sig
  type t = Member.t BatSet.t
  type elt = Member.t list
         
  val to_string: t -> string
  val of_string: string -> t option
                             
  val leave_group: t -> Member.t -> t
  val join_group: t -> Member.t -> t
                                     
end

(** 
  Holds State for group membership 
  Is a Monoid with the binary operation of merge 
*)                
                     
module State : sig
  type t = (string, Group.t ) BatHashtbl.t
  type elt = (string * Group.elt) list
         
  val join_group: t -> string -> Member.t -> t
  val leave_group: t -> string -> Member.t -> t
  val state_t: elt Depyt.t
                  
                                                
  val merge: t -> t -> t
  val zero: t
              
  val view_group: t -> string -> Group.t 
  val of_string: string -> t option
                             
  val to_string: t -> string
  val list_groups: t -> string list      
end 


module TMSG : sig
  type t =
    Join of (string * Member.t) |
    Leave of (string * Member.t) |
    ViewGroup of string |
    ListGroups
    
  val to_string: t -> string
  val of_string: string -> t option
                             
end
