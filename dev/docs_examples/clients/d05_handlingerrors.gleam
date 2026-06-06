import fhir/r4/client_httpc
import fhir/r4/sansio
import gleam/dynamic/decode
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/string

pub fn main() {
  let assert Ok(client) = sansio.fhirclient_new("https://r4.smarthealthit.org/")
  let pat =
    client_httpc.patient_read("87a339d0-8cae-418e-89c7-8651e6aab3c6", client)
  io.println(case pat {
    Ok(pat) -> {
      case pat.id {
        Some(id) -> "happy path! id is " <> id
        None -> panic as "server should always set patient id"
      }
    }
    Error(err) ->
      case err {
        client_httpc.ErrHttpc(_err) ->
          "httpc client couldn't connect to the server, maybe fhir client baseurl is wrong"
        client_httpc.ErrSansio(err) ->
          case err {
            client_httpc.ErrServer(err) ->
              "server responded but not with the json we asked for, instead got "
              <> err.body
            client_httpc.ErrOperationoutcome(err) ->
              "server sent an OperationOutcome "
              <> err.issue.first.diagnostics
              |> option.unwrap(" without diagnostics")
            client_httpc.ErrNoId ->
              panic as "only update/delete should hit this as it comes from calling fn with a resource"
            client_httpc.ErrParseJson(err) ->
              case err {
                json.UnableToDecode(errors) ->
                  "error parsing json: "
                  <> list.map(errors, fn(error) {
                    let decode.DecodeError(expected:, found:, path:) = error
                    "expected "
                    <> expected
                    <> " but found "
                    <> found
                    <> " at "
                    <> string.join(path, "/")
                  })
                  |> string.join(";")
                _ -> "bad json"
              }
          }
      }
  })
}
