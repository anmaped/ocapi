open Js_of_ocaml

let _ =
  print_endline "Hello world!" ;
  Js.export "myLib"
    (object%js
       method main () = print_endline "main"

       method add x y = x + y

       method abs x = abs_float x

       val zero = 0.
    end )
