open Lwt.Infix

let compile_handler request =
  Dream.body request
  >>= fun body ->
  let code =
    match Yojson.Basic.from_string body with
    | `Assoc [("code", `String c)] -> c
    | _ -> ""
  in
  if code = "" then
    Dream.json ~status:`Bad_Request
      "{\"error\": \"Missing 'code' field in JSON\"}"
  else
    Compile.compile_in_docker code
    >>= function
    | Ok wasm ->
        Dream.respond ~headers:[("Content-Type", "application/wasm")] wasm
    | Error err ->
        Dream.json ~status:`Bad_Request
          (Printf.sprintf {|{"error": "%s"}|} err)

let serve_favicon _req =
  Lwt_io.(with_file ~mode:Input "favicon.ico" read)
  >>= fun data ->
  Dream.respond ~headers:[("Content-Type", "image/x-icon")] data

let () =
  let app =
    Dream.router
      [ Dream.get "/favicon.ico" serve_favicon
      ; Dream.get "/" (Dream.from_filesystem "static" "index.html")
      ; Dream.post "/compile" compile_handler
      ; Dream.get "/run" (Dream.from_filesystem "static" "run.html")
      ; Dream.get "/doc" (Dream.from_filesystem "static" "doc.html")
      ; Dream.get "/ocapi.css" (Dream.from_filesystem "static" "ocapi.css")
      ; Dream.get "/examples/rmtld3synth_simple_monitor.ml"
          (Dream.from_filesystem "unittest" "rmtld3synth_simple_monitor.ml")
      ]
    |> Dream.logger
  in
  Dream.run ~interface:"0.0.0.0" app
