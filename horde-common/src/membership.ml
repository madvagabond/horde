module BatHashTbl = Batteries.BatHashtbl
module BatSet = Batteries.BatSet

let from_result res =
  match res with
  | Ok x -> Some x
  | Error x -> None 

module Protocol = struct 
  type t =
    Join of (string, Member.t) |
    Leave of (string, Member.t) |
    ViewGroup of string |
    Exchange of (State.t) |
    ListGroups

  let t =
    let open Depyt in
    
end

                    
module Member = struct
  type t = {protocol: string; host: string; port: int}

  let t =
    let open Depyt in
    record "t" (fun protocol host port -> {protocol; host; port;})
    |+ field protocol string (fun m -> m.protocol) 
    |+ field host string (fun m -> m.host)
    |+ field port int (fun m -> m.port)
    |> sealr      
             
  let to_string m =
    let fs = (Depyt.pp_json t) m in
    Fmt.strf "%a\n" fs 

  let of_string body =
    let decoder = Jsonm.decoder (`String body) in 
    Depyt.decode_json t decoder |> from_result

  let host m = m.host

  let port m = m.port

  let protocol m = m.protocol

  let compare l r =
    String.compare (to_string l) (to_string r)
                   
end



                  
module Group = struct
  type t = Member.t BatSet.t

  let t =
    let open Depyt in
    list Member.t
         
  let to_string grp =
    let data = BatSet.to_list grp in
    let fmt = (Depyt.pp_json t) grp in
    Fmt.strf "%a\n" fmt

  let of_string body =
    let decoder = Jsonm.decoder (`String body) in 
    let o = Depyt.decode_json state_t decoder |> from_result in
    Option.map (fun x -> BatSet.of_list x)

  let leave_group grp m =
    BatSet.remove m grp

  let join_group grp m =
    BatSet.add m grp 
end




                 
module State = struct
  type t = (string, (list Member.t) ) Hashtbl.t

  let state_t =
    let open Depyt in
    let kv = pair string v in
    list kv 

  let zero = Hashtbl.create 60
         
  let view_group t id =
    Hashtbl.find_opt t id |>
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
    BatHashTbl.keys t |> Batteries.BatList.of_enum

  let to_string t =
    let fs = BatHashTbl.to_list t in
    let data = List.map (fun k -> to_l k) fs in
    Fmt.strf "%a \n" ( (Depyt.pp_json state_t) grp )

  let of_string t =
    let decoder = Jsonm.decoder (`String body) in 
    let o = Depyt.decode_json state_t decoder |> from_result in
    let o1 = Option.map(fun x -> decode_help l) 
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
             
      | [] -> l in
    
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
