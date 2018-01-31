module Common = Horde_common
module Lwt_ZSock = Common.ZMQ_helpers.Lwt_ZSock
                     
module TMSG = Common.Membership.TMSG
module Member = Common.Membership.Member
module Group = Common.Membership.Group
                 
                  
                
type t = {req: [`Req] Lwt_ZSock.t; sub: [`Sub] Lwt_ZSock;}
type sub_cb = TMSG.t Lwt.t -> unit Lwt.t
                                   
val make: string -> string -> t 
val watch_group: t -> string -> sub_cb -> unit  Lwt.t
                                                
val join_group: t -> string -> Member.t -> unit Lwt.t 
val leave_group: t -> string -> Member.t -> unit Lwt.t
                                  
val view_group: t -> string -> (Group.t option) Lwt.t
val list_groups: t -> ( (string list) option) Lwt.t
                        
