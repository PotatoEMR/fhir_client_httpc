import fhir/r4/client_httpc
import fhir/r4/complex_types as ct
import fhir/r4/resources
import fhir/r4/valuesets
import gleam/option.{None, Some}

pub fn main() {
  let joe =
    resources.Patient(
      ..resources.patient_new(),
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

  let assert Ok(client) =
    client_httpc.fhirclient_new("https://hapi.fhir.org/baseR4")

  let params =
    resources.Parameters(..resources.parameters_new(), parameter: [
      resources.ParametersParameter(
        ..resources.parameters_parameter_new("resource"),
        resource: Some(resources.ResourcePatient(joe)),
      ),
    ])

  let assert Ok(_) =
    client_httpc.operation_any(
      params: Some(params),
      operation_name: "validate",
      res_type: resources.RtPatient,
      res_id: None,
      res_decoder: resources.operationoutcome_decoder(),
      return_res_type: resources.RtOperationoutcome,
      client:,
    )

  let assert Ok(created) = client_httpc.patient_create(joe, client)

  let assert Ok(_) =
    client_httpc.operation_any(
      params: None,
      operation_name: "everything",
      res_type: resources.RtPatient,
      res_id: created.id,
      res_decoder: resources.bundle_decoder(),
      return_res_type: resources.RtBundle,
      client:,
    )
}
