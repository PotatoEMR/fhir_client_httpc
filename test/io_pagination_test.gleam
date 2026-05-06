import fhir/r4/client_httpc as r4_httpc

// import fhir/r4/resources as r4

// import gleam/io
// import gleam/json

// runs against an external FHIR server, i.e. may fail because of server
pub fn io_pagination_test() {
  let assert Ok(client) =
    r4_httpc.fhirclient_new("https://r4.smarthealthit.org")

  let assert Ok(_bundle) =
    r4_httpc.search_any("name=e&_count=10", "Patient", client)
    |> r4_httpc.all_pages(client)
  // bundle |> r4.bundle_to_json |> json.to_string |> io.println
}
