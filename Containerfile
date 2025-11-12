FROM ocaml/opam:debian-ocaml-5.2

RUN sudo apt update &&  \
    sudo apt install -y m4 make gcc pkg-config libev-dev libgmp-dev libssl-dev docker-cli && \
    opam update && eval $(opam env) && \
    opam install -y dream yojson lwt

USER root
COPY . /app/.
RUN eval $(opam env) && cd /app && dune build

WORKDIR /app
CMD ["dune", "exec", "./server.exe"]
