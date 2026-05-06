import fhir/r4/client_httpc as r4_httpc
import fhir/r4/complex_types as ct_r4
import fhir/r4/resources as r4
import fhir/r4/sansio as r4_sansio
import fhir/r4/valuesets as r4_valuesets

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
    r4.Patient(
      ..r4.patient_new(),
      text: Some(ct_r4.narrative_new(
        div: "<div xmlns=\"http://www.w3.org/1999/xhtml\">Joe Armstrong</div>",
        status: r4_valuesets.NarrativestatusGenerated,
      )),
      identifier: [
        ct_r4.Identifier(
          ..ct_r4.identifier_new(),
          system: Some("https://fhir.nhs.uk/Id/nhs-number"),
          value: Some("0123456789"),
        ),
      ],
      name: [
        ct_r4.Humanname(
          ..ct_r4.humanname_new(),
          given: ["Joe"],
          family: Some("Armstrong"),
        ),
      ],
      gender: Some(r4_valuesets.AdministrativegenderMale),
      marital_status: Some(
        ct_r4.Codeableconcept(..ct_r4.codeableconcept_new(), coding: [
          ct_r4.Coding(
            ..ct_r4.coding_new(),
            system: Some(
              "http://terminology.hl7.org/CodeSystem/v3-MaritalStatus",
            ),
            code: Some("M"),
            display: Some("Married"),
          ),
        ]),
      ),
    )

  let assert Ok(client) =
    r4_httpc.fhirclient_new("https://r4.smarthealthit.org")

  let assert Ok(created) = r4_httpc.patient_create(joe, client)
  let assert Some(id) = created.id
  let assert Ok(read) = r4_httpc.patient_read(id, client)
  let rip = r4.Patient(..read, deceased: Some(r4.PatientDeceasedBoolean(True)))
  let assert Ok(updated) = r4_httpc.patient_update(rip, client)
  let assert Ok(bundle) =
    r4_httpc.patient_search_bundled(
      r4_sansio.SpPatient(..r4_sansio.sp_patient_new(), name: Some("Armstrong")),
      client,
    )
    |> r4_httpc.all_pages(client)
  let pats = { bundle |> r4_sansio.bundle_to_groupedresources }.patient
  echo bundle.total
  let assert Ok(_) = list.find(pats, fn(pat) { pat.id == Some(id) })

  let assert Ok(bundle) =
    r4_httpc.search_any("name=Armstrong", "Patient", client)
    |> r4_httpc.all_pages(client)
  let pats = { bundle |> r4_sansio.bundle_to_groupedresources }.patient
  let assert Ok(_) = list.find(pats, fn(pat) { pat.id == Some(id) })
    as { "search 1 did not find " <> id }

  let assert Ok(_) = r4_httpc.patient_delete(updated, client)
  Nil
}
