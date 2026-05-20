import fhir/r4/client_httpc
import fhir/r4/complex_types as ct
import fhir/r4/resources
import fhir/r4/sansio
import fhir/r4/valuesets
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{Some}

pub fn main() {
  let pat_id = "a-specific-id"
  let joe =
    resources.Patient(
      ..resources.patient_new(),
      id: Some(pat_id),
      name: [
        ct.Humanname(
          ..ct.humanname_new(),
          given: ["Joe", "Leslie"],
          family: Some("Armstrong"),
        ),
      ],
      gender: Some(valuesets.AdministrativegenderMale),
    )

  let assert Ok(client) = client_httpc.fhirclient_new("r4.smarthealthit.org")

  // When processing a batch or transaction, a server MAY
  // choose to honor existing logical ids
  // (e.g., Observation/1234 remains as Observation/1234 on the server),
  // but since this is only safe in controlled circumstances,
  // servers may choose to assign new ids to all submitted resources,
  // irrespective of any claimed logical id in the resource
  let assert Ok(upsert_req) =
    sansio.any_update_req(
      joe.id,
      resources.patient_to_json(joe),
      "Patient",
      client,
    )
  let read_req = sansio.any_read_req(pat_id, "Patient", client)
  let assert Ok(batch_bundle) =
    client_httpc.batch([upsert_req, read_req], sansio.Transaction, client)
  batch_bundle |> resources.bundle_to_json |> json.to_string |> io.println

  let batch_response = batch_bundle.entry

  let assert Ok(_) =
    list.find(batch_response, fn(entry) {
      case entry.response {
        Some(resp) ->
          case resp.status {
            "201" <> _ -> True
            "200" <> _ -> True
            _ -> False
          }
        _ -> False
      }
    })

  // if we did this delete as part of the transaction,
  // the server would process it *before* the update and read
  // rather than after
  let assert Ok(_) = client_httpc.patient_delete(joe, client)
}
