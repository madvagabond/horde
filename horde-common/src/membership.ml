module BatHashTbl = Batteries.Hashtbl
module BatSet = Batteries.Set
module Option = Batteries.Option
                  

let from_result res =
  match res with
  | Ok x -> Some x
  | Error x -> None 


module Member = struct
  type t = {protocol: string; host: string; port: int}

  let t =
    let open Depyt in
    record "t" (fun protocol host port -> {protocol; host; port;})
    |+ field "protocol" string (fun m -> m.protocol) 
    |+ field "host" string (fun m -> m.host)
    |+ field "port" int (fun m -> m.port)
    |> sealr      
             
  let to_string m =
    Fmt.strf "%a \n" (Depyt.pp_json t) m 

  let of_string body =
    let decoder = Jsonm.decoder (`String body) in 
    Depyt.decode_json t decoder |> from_result

  let to_address m =
    Fmt.strf "%s://%s:%d" m.protocol m.host m.port
             
  let host m = m.host

  let port m = m.port

  let protocol m = m.protocol

  let compare l r =
    String.compare (to_address l) (to_address l)
end





module Group = struct
  type t = Member.t BatSet.t

  let t =
    let open Depyt in
    list Member.t
         
  let to_string grp =
    let data = BatSet.to_list grp in
    Fmt.strf "%a\n" (Depyt.pp_json t) data 

  let of_string body =
    let decoder = Jsonm.decoder (`String body) in 
    let o = Depyt.decode_json t decoder |> from_result in
    Option.map (fun x -> BatSet.of_list x) o

  let leave_group grp m =
    BatSet.remove m grp

  let join_group grp m =
    BatSet.add m grp 
end




                 
module State = struct
  type t = (string, Group.t ) Hashtbl.t
  type elt =(string * Member.t list) list

  let state_t =
    let open Depyt in
    let kv = pair string Group.t in
    list kv 

  let zero = Hashtbl.create 60
         
  let view_group t id =
    BatHashtbl.find_option t id |>
    function
    | Some x -> x
    | None -> BatSet.empty

  let of_l tup =
    let k, v = tup in
    (k, (BatSet.of_list v) )

  let to_l tup =
    let k, v = tup in
    (k, (BatSet.to_list v) )

  let decode_help l =
    List.map (fun x -> of_l x) l 
                
  let list_groups t =
    BatHashTbl.keys t |> Batteries.List.of_enum

  let to_string t =
    let fs = BatHashTbl.to_list t in
    let data = List.map (fun k -> to_l k) fs in
    Fmt.strf "%a\n" (Depyt.pp_json state_t) data 

  let of_string body =
    let decoder = Jsonm.decoder (`String body) in 
    let o = Depyt.decode_json state_t decoder |> from_result in
    let o1 = Option.map (fun x -> decode_help x) o in
    Option.map (fun x -> BatHashTbl.of_list x ) o1
   
  let merge l r =
    
    let rec handle_right kvl =
      match kvl with
      | hd :: tl ->
         let k, v = hd in
         
         if BatHashTbl.mem l k then
           let cv = BatHashTbl.find l k in
           BatHashTbl.add l k (BatSet.union cv v)
                          
         else
           BatHashTbl.add l k v;
         
         handle_right tl
             
      | [] -> l
    in
  
    let rl = BatHashTbl.to_list r in
    handle_right rl


  let join_group t gid m =
    let grp = view_group t gid in
    let grp1 = Group.join_group grp m in 
    BatHashTbl.replace t gid grp1;
    t 

  let leave_group t gid m =
    let grp = view_group t gid in
    let grp1 = Group.leave_group grp m in
    BatHashTbl.replace t gid grp1;
    t
    
end



                 
module TMSG = struct 
  type t =
    Join of (string * Member.t) |
    Leave of (string * Member.t) |
    ViewGroup of string |
    Exchange of State.elt |
    ListGroups
             
  let t =
    let open Depyt in
    variant "t" (fun join leave viewgroup exchange listgroups -> function
        | Join x -> join x
        | Leave x -> leave x
        | ViewGroup x -> viewgroup x
        | Exchange x -> exchange x
        | ListGroups -> listgroups
      ) 
    |~ case1 "Join" (pair string Member.t) (fun x -> Join x)
    |~ case1 "Leave" (pair string Member.t) (fun x -> Leave x)
    |~ case1 "ViewGroup" string (fun x -> ViewGroup x)
    |~ case1 "Exchange" State.state_t (fun x -> Exchange x)
    |~ case0 "ListGroups" ListGroups
    |> sealv

  let to_string m =
    Fmt.strf "%a\n" (Depyt.pp_json t) m  

  let of_string body =
    let decoder = Jsonm.decoder (`String body) in 
    Depyt.decode_json t decoder |> from_result
    
         
end

module RMSG = struct
  type t = {success: bool; data: string}    
end 
                    


                  
