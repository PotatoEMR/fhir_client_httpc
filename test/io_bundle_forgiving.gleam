import fhir/r4/client_httpc
import fhir/r4/resources
import fhir/r4/sansio
import gleam/list
import gleam/option.{None, Some}

pub fn main() {
  let assert Ok(client) = sansio.fhirclient_new("https://hapi.fhir.org/baseR4/")
  let assert Ok(mixed_bundle) =
    client_httpc.search_any_forgiving(
      "_count=100",
      resources.RtDocumentreference,
      client,
    )
    |> client_httpc.all_pages_forgiving(client)
  echo mixed_bundle.entry |> list.length

  echo mixed_bundle.entry
    |> list.filter(fn(e) {
      case e.resource {
        Some(Ok(_)) -> True
        Some(Error(_)) -> False
        None -> panic as "uh"
      }
    })
    |> list.length

  echo mixed_bundle.entry
    |> list.filter(fn(e) {
      case e.resource {
        Some(Ok(_)) -> False
        Some(Error(_)) -> True
        None -> panic as "hmm"
      }
    })
    |> echo
    |> list.length
}
