open Lwt.Infix
open Printf

let compile_in_docker code =
  let tmpdir = Filename.get_temp_dir_name () in
  let ml_path = Filename.concat tmpdir "code.ml" in
  let wasm_path = Filename.concat tmpdir "code.zip" in
  Dream.log "Running in container ..." ;
  (* Write user code to temporary file *)
  let oc = open_out ml_path in
  output_string oc code ;
  close_out oc ;
  (* Run the compiler container with limited privileges *)
  let cmd =
    sprintf
      "cat %s | docker run --rm -i --cpus=0.5 --memory=256m --network=none \
       --pids-limit=50 ocaml-wasm-compiler 'cat > input.ml && eval \"$(opam \
       env)\" && dune build --profile release ./input.bc.wasm.js && cd _build/default/ && zip -r archive_name.zip ./ -x \".*/*\" -x \"*-jsoo\" -x \"*.ml\" -x \"*.mli\" && cat \
       archive_name.zip ' > %s"
      ml_path wasm_path
  in
  Dream.log "CMD: %s" cmd ;
  let process =
    Lwt_process.open_process_full ("/bin/sh", [|"/bin/sh"; "-c"; cmd|])
  in
  let output = Lwt_io.read process#stderr in
  let status = process#status in
  Lwt.both status output
  >>= fun (status, output) ->
  match status with
  | Unix.WEXITED 0 ->
      Dream.log "Compilation succeeded" ;
      Lwt_io.(with_file ~mode:Input wasm_path read) >|= fun bytes -> Ok bytes
  | Unix.WSIGNALED n ->
      Dream.log "Compilation killed by signal %d: %s" n output ;
      Lwt.return (Error output)
  | Unix.WSTOPPED n ->
      Dream.log "Compilation stopped by signal %d: %s" n output ;
      Lwt.return (Error output)
  | _ ->
      Dream.log "Compilation failed: %s" output ;
      Lwt.return (Error output)
