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

let () =
  let app =
    Dream.router
      [ Dream.post "/compile" compile_handler
      ; Dream.get "/" (Dream.from_filesystem "static" "index.html")
      ; Dream.get "/run" (Dream.from_filesystem "static" "run.html") ]
    |> Dream.logger
  in
  Dream.run ~interface:"0.0.0.0" app
