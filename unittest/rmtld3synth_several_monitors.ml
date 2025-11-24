(* This file was automatically generated from rmtld3synth tool version
v0.7-2-gea1a1ac (ea1a1acb64d37403a5a1b42c65f320705eb4516f)
x86_64 GNU/Linux 2025-11-24 02:35.
 *)

(* Settings:
   {
     "gen_tests": false,
     "prop_map": "(b->1) (a->2) ",
     "input_exp_dsl": [ "a until b within 10s", "duration of a in [0,10] < 6", "a or b" ],
     "rtm_max_period": 2000000,
     "init": true,
     "rtm_min_inter_arrival_time": 1,
     "prop_map_reverse": "(2->a) (1->b) ",
     "rtm_period": 200000,
     "fm_num_prop": 2,
     "rtm_monitor_time_unit": "s",
     "rtm_monitor_name_prefix": "rtm_#_%",
     "input_exp": [ "(a U[10.] b)", "(int[10.] (a) < 6.)", "(a or b)" ],
     "version": "v0.7-2-gea1a1ac (ea1a1acb64d37403a5a1b42c65f320705eb4516f)
   x86_64 GNU/Linux 2025-11-24 02:35",
     "rtm_buffer_size": 100
   }
   
   Formula(s):
   - (a or b)
   - (int[10.] (a) < 6.)
   - (a U[10.] b)
   
 *) 
open Rmtld3_eval

module type Trace = sig val trc : trace end

module Rtm_compute_97f7_2  ( T : Trace  ) = struct 
  let env = environment T.trc
  let lg_env = lenv
  let t = 0.
  let mon = (eval_uless 10. (fun k s t -> k.evaluate k.trc "a" t) (fun k s t -> k.evaluate k.trc "b" t)) env lg_env t
end

module Rtm_compute_97f7_1  ( T : Trace  ) = struct 
  let env = environment T.trc
  let lg_env = lenv
  let t = 0.
  let mon = (fun k s t -> b3_lessthan ((eval_tm_duration (fun k s t -> Dsome(10.) ) (fun k s t -> k.evaluate k.trc "a" t)) k s t) ((fun k s t -> Dsome(6.) ) k s t)) env lg_env t
end

module Rtm_compute_97f7_0  ( T : Trace  ) = struct 
  let env = environment T.trc
  let lg_env = lenv
  let t = 0.
  let mon = (fun k s t -> b3_or ((fun k s t -> k.evaluate k.trc "a" t) k s t) ((fun k s t -> k.evaluate k.trc "b" t) k s t)) env lg_env t
end


type monitor_factory = (module Trace) -> Rmtld3_eval.three_valued

let registry : (string * string * monitor_factory) list =
  [
    ( "Rtm_compute_97f7_2"
    , "(a U[10.] b)"
    , fun (module T) ->
        let module M = Rtm_compute_97f7_2 (T) in
        M.mon );
    ( "Rtm_compute_97f7_1"
    , "(int[10.] (a) < 6.)"
    , fun (module T) ->
        let module M = Rtm_compute_97f7_1 (T) in
        M.mon );
    ( "Rtm_compute_97f7_0"
    , "(a or b)"
    , fun (module T) ->
        let module M = Rtm_compute_97f7_0 (T) in
        M.mon );
  ]
(* End of generated file *)


(* Construct a list trc for each registry entry *)
let traces = List.map (fun (id, desc, _f) -> (id, desc, ref [])) registry

let myMonitor_set id trc =
  let trace_entry = List.find (fun (tid, _, _) -> tid = id) traces in
  match trace_entry with
  | _, _, lst -> lst := trc
  | _ -> failwith "Trace ID not found"

let myMonitor_run id () =
  let trace_entry = List.find (fun (tid, _, _) -> tid = id) traces in
  match trace_entry with
  | _, _, lst -> (
      let module T : Trace = struct
        let trc = !lst
      end in
      let monitor_entry = List.find (fun (tid, _, _) -> tid = id) registry in
      match monitor_entry with
      | _, _, factory ->
          let result = factory (module T) in
          if result = Rmtld3_eval.True then print_endline "[true]"
          else if result = Rmtld3_eval.False then print_endline "[false]"
          else print_endline "[unknown]" ;
          result )

open Js_of_ocaml

let array_of_array_of_pairs trc =
  trc |> Js.to_array |> Array.to_list
  |> List.map (fun lst ->
      let p = Js.to_array lst in
      let s = Js.to_string p.(0) in
      (* first element: JS string -> string *)
      let f = p.(1) |> Js.Unsafe.coerce |> Js.float_of_number in
      (* second element: JS number -> float *)
      print_endline (Js.to_string p.(0) ^ "," ^ (f |> string_of_float)) ;
      (s, f) )

let list_monitors () =
  Js.string (String.concat ", " (List.map (fun (id, _, _) -> id) registry))

let _ =
  print_endline "Ready to run WebAssembly monitor module..." ;
  Js.export "myMonitor"
    (object%js
       method list () = list_monitors ()

       method run id = myMonitor_run (Js.to_string id) ()

       method set id trc =
         myMonitor_set (Js.to_string id) (array_of_array_of_pairs trc)
    end )
