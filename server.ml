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
        Dream.respond ~headers:[("Content-Type", "application/zip")] wasm
    | Error err ->
        Dream.json ~status:`Bad_Request
          (Printf.sprintf {|{"error": "%s"}|} err)

let favicon_handler _ =
  Lwt_io.(with_file ~mode:Input "favicon.ico" read)
  >>= fun data ->
  Dream.respond ~headers:[("Content-Type", "image/x-icon")] data

let () =
  let app =
    Dream.router
      [ Dream.get "/favicon.ico" favicon_handler
      ; Dream.get "/" (Dream.from_filesystem "static" "index.html")
      ; Dream.post "/compile" compile_handler
      ; Dream.get "/run" (Dream.from_filesystem "static" "run.html")
      ; Dream.get "/doc" (Dream.from_filesystem "static" "doc.html")
      ; Dream.get "/ocapi.css" (Dream.from_filesystem "static" "ocapi.css")
      ; Dream.get "/examples/:file" (fun request ->
            let path = Dream.param request "file" in
            Dream.from_filesystem "unittest" path request ) ]
    |> Dream.logger
  in
  Dream.run ~interface:"0.0.0.0" app
