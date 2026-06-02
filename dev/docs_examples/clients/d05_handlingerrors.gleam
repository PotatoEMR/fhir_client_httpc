import fhir/r4/client_httpc
import fhir/r4/sansio
import gleam/dynamic/decode
import gleam/httpc
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
        client_httpc.ErrHttpc(err) ->
          case err {
            httpc.InvalidUtf8Response -> "InvalidUtf8Response"
            httpc.FailedToConnect(ip4:, ip6:) ->
              "failed to connect: ip4 " <> ip4.code <> ", ip6 " <> ip6.code
            httpc.ResponseTimeout -> "Timeout"
          }
        client_httpc.ErrSansio(err) ->
          case err {
            client_httpc.ErrNotJson(err) -> "not json: " <> err.body
            client_httpc.ErrOperationoutcome(err) ->
              "OperationOutcome: "
              <> [err.issue.first, ..err.issue.rest]
              |> list.map(fn(issue) {
                case issue.diagnostics {
                  Some(err) -> err
                  None -> "issue without diagnostics"
                }
                <> string.join(issue.expression, "at ")
                <> string.join(issue.location, "at ")
              })
              |> string.join("\n")
            client_httpc.ErrNoId ->
              panic as "only update/delete should hit this as it comes from calling fn with a resource"
            client_httpc.ErrParseJson(err) ->
              case err {
                json.UnexpectedEndOfInput -> "UnexpectedEndOfInput"
                json.UnexpectedByte(err) -> "UnexpectedByte " <> err
                json.UnexpectedSequence(err) -> "UnexpectedSequence " <> err
                json.UnableToDecode(errors) ->
                  "UnableToDecode "
                  <> list.map(errors, fn(error) {
                    let decode.DecodeError(expected:, found:, path:) = error
                    "expected "
                    <> expected
                    <> " found "
                    <> found
                    <> " at "
                    <> string.join(path, "/")
                  })
                  |> string.join("\n")
              }
          }
      }
  })
}
