import fhir/r4/client_httpc
import fhir/r4/complex_types as ct
import fhir/r4/resources
import gleam/option.{Some}

pub fn main() {
  let assert Ok(client) =
    client_httpc.fhirclient_new("https://r4.smarthealthit.org/")

  // Create
  let pat =
    resources.Patient(..resources.patient_new(), name: [
      ct.Humanname(..ct.humanname_new(), given: ["Joe"]),
    ])
  let assert Ok(created) = client_httpc.patient_create(pat, client)
  echo created

  // Read
  let assert Some(c_id) = created.id
  let assert Ok(pat) = client_httpc.patient_read(c_id, client)
  echo pat

  // Update
  let pat =
    resources.Patient(..resources.patient_new(), id: Some("sgfdsgfdgfd"), name: [
      ct.Humanname(..ct.humanname_new(), given: ["Mike"]),
    ])
  let assert Ok(updated) = client_httpc.patient_update(pat, client)
  echo updated

  // Delete
  let assert Ok(deleted) =
    client_httpc.any_delete("sgfdsgfdgfd", resources.RtPatient, client)
  echo deleted
}
