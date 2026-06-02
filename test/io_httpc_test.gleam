import fhir/r4/client_httpc
import fhir/r4/complex_types as ct
import fhir/r4/resources
import fhir/r4/sansio
import fhir/r4/search_params
import fhir/r4/valuesets

import gleam/list
import gleam/option.{Some}

// these tests run against an external fhir server
// so they are good to check against the real world
// but may fail just because the server falls over!
// not necessarily because they're wrong
// also, there may be some request timing involved on the server side
// I have seen these pass sometimes and fail sometimes
// so idk
pub fn normal_r4_test() {
  let joe =
    resources.Patient(
      ..resources.patient_new(),
      text: Some(ct.narrative_new(
        div: "<div xmlns=\"http://www.w3.org/1999/xhtml\">Joe Armstrong</div>",
        status: valuesets.NarrativestatusGenerated,
      )),
      identifier: [
        ct.Identifier(
          ..ct.identifier_new(),
          system: Some("https://fhir.nhs.uk/Id/nhs-number"),
          value: Some("0123456789"),
        ),
      ],
      name: [
        ct.Humanname(
          ..ct.humanname_new(),
          given: ["Joe"],
          family: Some("Armstrong"),
        ),
      ],
      gender: Some(valuesets.AdministrativegenderMale),
      marital_status: Some(
        ct.Codeableconcept(..ct.codeableconcept_new(), coding: [
          ct.Coding(
            ..ct.coding_new(),
            system: Some(
              "http://terminology.hl7.org/CodeSystem/v3-MaritalStatus",
            ),
            code: Some("M"),
            display: Some("Married"),
          ),
        ]),
      ),
    )

  let assert Ok(client) = sansio.fhirclient_new("https://r4.smarthealthit.org")

  let assert Ok(created) = client_httpc.patient_create(joe, client)
  let assert Some(id) = created.id
  let assert Ok(read) = client_httpc.patient_read(id, client)
  let rip =
    resources.Patient(
      ..read,
      deceased: Some(resources.PatientDeceasedBoolean(True)),
    )
  let assert Ok(updated) = client_httpc.patient_update(rip, client)
  let assert Ok(bundle) =
    client_httpc.patient_search_bundled(
      search_params.Patient(
        ..search_params.patient_new(),
        name: Some("Armstrong"),
      ),
      client,
    )
    |> client_httpc.all_pages(client)
  let pats = { bundle |> sansio.bundle_to_groupedresources }.patient
  echo bundle.total
  let assert Ok(_) = list.find(pats, fn(pat) { pat.id == Some(id) })

  let assert Ok(bundle) =
    client_httpc.search_any("name=Armstrong", resources.RtPatient, client)
    |> client_httpc.all_pages(client)
  let pats = { bundle |> sansio.bundle_to_groupedresources }.patient
  let assert Ok(_) = list.find(pats, fn(pat) { pat.id == Some(id) })
    as { "search 1 did not find " <> id }

  let assert Ok(_) = client_httpc.patient_delete(updated, client)
  Nil
}
