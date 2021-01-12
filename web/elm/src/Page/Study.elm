module Page.Study exposing (Model, Msg, init, subscriptions, update, view)

import Bootstrap.Button as Button
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Table exposing (simpleThead, table, tbody, td, th, tr)
import Common exposing (commify, viewHttpErrorMessage)
import Config exposing (apiServer, serverAddress)
import Html exposing (Html, a, div, h1, h2, li, text, ul)
import Html.Attributes exposing (href, style, target)
import Http
import Json.Decode exposing (Decoder, field, float, int, nullable, string)
import Json.Decode.Pipeline exposing (hardcoded, optional, required)
import RemoteData exposing (RemoteData, WebData)
import Route
import Url.Builder


type alias Model =
    { study : WebData Study
    }


type alias Condition =
    { conditionId : Int
    , condition : String
    }


type alias Intervention =
    { interventionId : Int
    , intervention : String
    }


type alias Sponsor =
    { sponsorId : Int
    , sponsorName : String
    }


type alias Study =
    { nctId : String
    , officialTitle : String
    , briefTitle : String
    , detailedDescription : String
    , orgStudyId : String
    , acronym : String
    , source : String
    , rank : String
    , briefSummary : String
    , overallStatus : String
    , lastKnownStatus : String
    , whyStopped : String
    , phase : String
    , studyType : String
    , hasExpandedAccess : String
    , targetDuration : String
    , biospecRetention : String
    , biospecDescription : String
    , startDate : String
    , completionDate : String
    , verificationDate : String
    , studyFirstSubmitted : String
    , studyFirstSubmittedQC : String
    , studyFirstPosted : String
    , resultsFirstSubmitted : String
    , resultsFirstSubmittedQC : String
    , resultsFirstPosted : String
    , dispositionFirstSubmitted : String
    , dispositionFirstSubmittedQC : String
    , dispositionFirstPosted : String
    , lastUpdateSubmitted : String
    , lastUpdateSubmittedQC : String
    , lastUpdatePosted : String
    , primaryCompletionDate : String
    , sponsors : List Sponsor
    , conditions : List Condition
    , interventions : List Intervention
    }


type Msg
    = StudyResponse (WebData Study)


init : String -> ( Model, Cmd Msg )
init nctId =
    ( { study = RemoteData.NotAsked
      }
    , Cmd.batch [ getStudy nctId ]
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StudyResponse data ->
            ( { model | study = data }
            , Cmd.none
            )


view : Model -> Html Msg
view model =
    let
        studyView =
            case model.study of
                RemoteData.NotAsked ->
                    div [] [ text "Not asked" ]

                RemoteData.Loading ->
                    div [] [ text "Loading data..." ]

                RemoteData.Failure httpError ->
                    div [] [ text (viewHttpErrorMessage httpError) ]

                RemoteData.Success study ->
                    div []
                        [ h1 [] [ text <| "Study: " ++ study.nctId ]
                        , studyTable study
                        ]
    in
    Grid.container []
        [ Grid.row []
            [ Grid.col [ Col.md8 ] [ studyView ]
            ]
        ]


studyTable : Study -> Html Msg
studyTable study =
    let
        mkUl items =
            case List.length items of
                0 ->
                    text ""

                _ ->
                    ul [] (List.map (\item -> li [] [ text item ]) items)
    in
    table
        { options = [ Bootstrap.Table.striped ]
        , thead = simpleThead []
        , tbody =
            tbody []
                [ tr []
                    [ th [] [ text "NCT ID" ]
                    , td []
                        [ a
                            [ href <|
                                "https://clinicaltrials.gov/ct2/show/"
                                    ++ study.nctId
                            , target "_blank"
                            ]
                            [ text study.nctId ]
                        ]
                    ]
                , tr []
                    [ th [] [ text "Brief Title" ]
                    , td [] [ text study.briefTitle ]
                    ]
                , tr []
                    [ th [] [ text "Official Title" ]
                    , td [] [ text study.officialTitle ]
                    ]
                , tr []
                    [ th [] [ text "Detailed Description" ]
                    , td [] [ text study.detailedDescription ]
                    ]
                , tr []
                    [ th [] [ text "Brief Summary" ]
                    , td [] [ text study.briefSummary ]
                    ]
                , tr []
                    [ th [] [ text "Overall Status" ]
                    , td [] [ text study.overallStatus ]
                    ]
                , tr []
                    [ th [] [ text "Last Known Status" ]
                    , td [] [ text study.lastKnownStatus ]
                    ]
                , tr []
                    [ th [] [ text "Why Stopped" ]
                    , td [] [ text study.whyStopped ]
                    ]
                , tr []
                    [ th [] [ text "Phase" ]
                    , td [] [ text study.phase ]
                    ]
                , tr []
                    [ th [] [ text "Study Type" ]
                    , td [] [ text study.studyType ]
                    ]
                , tr []
                    [ th [] [ text "Org Study ID" ]
                    , td [] [ text study.orgStudyId ]
                    ]
                , tr []
                    [ th [] [ text "Acronym" ]
                    , td [] [ text study.acronym ]
                    ]
                , tr []
                    [ th [] [ text "Rank" ]
                    , td [] [ text study.rank ]
                    ]
                , tr []
                    [ th [] [ text "Has Expanded Access" ]
                    , td [] [ text study.hasExpandedAccess ]
                    ]
                , tr []
                    [ th [] [ text "Target Duration" ]
                    , td [] [ text study.targetDuration ]
                    ]
                , tr []
                    [ th []
                        [ text <|
                            "Conditions ("
                                ++ String.fromInt (List.length study.conditions)
                                ++ ")"
                        ]
                    , td []
                        [ mkUl (List.map (\c -> c.condition) study.conditions)
                        ]
                    ]
                , tr []
                    [ th []
                        [ text <|
                            "Interventions ("
                                ++ String.fromInt
                                    (List.length study.interventions)
                                ++ ")"
                        ]
                    , td []
                        [ mkUl
                            (List.map
                                (\i -> i.intervention)
                                study.interventions
                            )
                        ]
                    ]
                , tr []
                    [ th []
                        [ text <|
                            "Sponsors ("
                                ++ String.fromInt (List.length study.sponsors)
                                ++ ")"
                        ]
                    , td []
                        [ mkUl (List.map (\s -> s.sponsorName) study.sponsors)
                        ]
                    ]
                ]
        }


alignRight =
    Bootstrap.Table.cellAttr (style "text-align" "right")


getStudy : String -> Cmd Msg
getStudy nctId =
    let
        url =
            apiServer ++ "/study/" ++ nctId
    in
    Http.get
        { url = url
        , expect =
            Http.expectJson
                (RemoteData.fromResult >> StudyResponse)
                decoderStudy
        }


decoderStudy : Decoder Study
decoderStudy =
    Json.Decode.succeed Study
        |> Json.Decode.Pipeline.required "nct_id" string
        |> Json.Decode.Pipeline.required "official_title" string
        |> Json.Decode.Pipeline.required "brief_title" string
        |> Json.Decode.Pipeline.required "detailed_description" string
        |> Json.Decode.Pipeline.required "org_study_id" string
        |> Json.Decode.Pipeline.required "acronym" string
        |> Json.Decode.Pipeline.required "source" string
        |> Json.Decode.Pipeline.required "rank" string
        |> Json.Decode.Pipeline.required "brief_summary" string
        |> Json.Decode.Pipeline.required "overall_status" string
        |> Json.Decode.Pipeline.required "last_known_status" string
        |> Json.Decode.Pipeline.required "why_stopped" string
        |> Json.Decode.Pipeline.required "phase" string
        |> Json.Decode.Pipeline.required "study_type" string
        |> Json.Decode.Pipeline.required "has_expanded_access" string
        |> Json.Decode.Pipeline.required "target_duration" string
        |> Json.Decode.Pipeline.required "biospec_retention" string
        |> Json.Decode.Pipeline.required "biospec_description" string
        |> Json.Decode.Pipeline.required "start_date" string
        |> Json.Decode.Pipeline.required "completion_date" string
        |> Json.Decode.Pipeline.required "verification_date" string
        |> Json.Decode.Pipeline.required "study_first_submitted" string
        |> Json.Decode.Pipeline.required "study_first_submitted_qc" string
        |> Json.Decode.Pipeline.required "study_first_posted" string
        |> Json.Decode.Pipeline.required "results_first_submitted" string
        |> Json.Decode.Pipeline.required "results_first_submitted_qc" string
        |> Json.Decode.Pipeline.required "results_first_posted" string
        |> Json.Decode.Pipeline.required "disposition_first_submitted" string
        |> Json.Decode.Pipeline.required "disposition_first_submitted_qc" string
        |> Json.Decode.Pipeline.required "disposition_first_posted" string
        |> Json.Decode.Pipeline.required "last_update_submitted" string
        |> Json.Decode.Pipeline.required "last_update_submitted_qc" string
        |> Json.Decode.Pipeline.required "last_update_posted" string
        |> Json.Decode.Pipeline.required "primary_completion_date" string
        |> Json.Decode.Pipeline.optional "sponsors"
            (Json.Decode.list decoderSponsor)
            []
        |> Json.Decode.Pipeline.optional "conditions"
            (Json.Decode.list decoderCondition)
            []
        |> Json.Decode.Pipeline.optional "interventions"
            (Json.Decode.list decoderIntervention)
            []


decoderSponsor : Decoder Sponsor
decoderSponsor =
    Json.Decode.succeed Sponsor
        |> Json.Decode.Pipeline.required "sponsor_id" int
        |> Json.Decode.Pipeline.required "sponsor_name" string


decoderCondition : Decoder Condition
decoderCondition =
    Json.Decode.succeed Condition
        |> Json.Decode.Pipeline.required "condition_id" int
        |> Json.Decode.Pipeline.required "condition" string


decoderIntervention : Decoder Intervention
decoderIntervention =
    Json.Decode.succeed Intervention
        |> Json.Decode.Pipeline.required "intervention_id" int
        |> Json.Decode.Pipeline.required "intervention" string


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
