module Page.Study exposing (Model, Msg, init, subscriptions, update, view)

import Bootstrap.Button as Button
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Tab as Tab
import Bootstrap.Table exposing (rowPrimary, simpleThead, table, tbody, td, th, tr)
import Bootstrap.Utilities.Spacing as Spacing
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
    , tabState : Tab.State
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


type alias StudyOutcome =
    { studyOutcomeId : Int
    , outcomeType : String
    , measure : String
    , timeFrame : String
    , description : String
    }


type alias StudyDoc =
    { studyDocId : Int
    , docId : String
    , docType : String
    , docUrl : String
    , docComment : String
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
    , studyOutcomes : List StudyOutcome
    , studyDocs : List StudyDoc
    }


type Msg
    = TabMsg Tab.State
    | StudyResponse (WebData Study)


init : String -> ( Model, Cmd Msg )
init nctId =
    ( { study = RemoteData.NotAsked
      , tabState = Tab.initialState
      }
    , Cmd.batch [ getStudy nctId ]
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TabMsg state ->
            ( { model | tabState = state }
            , Cmd.none
            )

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
                        , studyTab model.tabState study
                        ]
    in
    Grid.container []
        [ Grid.row []
            [ Grid.col [] [ studyView ]
            ]
        ]


studyTab : Tab.State -> Study -> Html Msg
studyTab tabState study =
    let
        conditionsTabTitle =
            "Conditions ("
                ++ String.fromInt (List.length study.conditions)
                ++ ")"

        interventionsTabTitle =
            "Interventions ("
                ++ String.fromInt
                    (List.length study.interventions)
                ++ ")"

        sponsorsTabTitle =
            "Sponsors ("
                ++ String.fromInt
                    (List.length study.sponsors)
                ++ ")"

        studyDocsTabTitle =
            "Docs ("
                ++ String.fromInt
                    (List.length study.studyDocs)
                ++ ")"

        studyOutcomesTabTitle =
            "Outcomes ("
                ++ String.fromInt
                    (List.length study.studyOutcomes)
                ++ ")"
    in
    Tab.config TabMsg
        |> Tab.items
            [ Tab.item
                { id = "tabGeneral"
                , link = Tab.link [] [ text "General" ]
                , pane =
                    Tab.pane [ Spacing.mt3 ]
                        [ viewStudy study
                        ]
                }
            , Tab.item
                { id = "tabConditions"
                , link = Tab.link [] [ text conditionsTabTitle ]
                , pane =
                    Tab.pane [ Spacing.mt3 ]
                        [ viewConditions study.conditions ]
                }
            , Tab.item
                { id = "tabInterventions"
                , link = Tab.link [] [ text interventionsTabTitle ]
                , pane =
                    Tab.pane [ Spacing.mt3 ]
                        [ viewInterventions study.interventions ]
                }
            , Tab.item
                { id = "tabSponsors"
                , link = Tab.link [] [ text sponsorsTabTitle ]
                , pane =
                    Tab.pane [ Spacing.mt3 ]
                        [ viewSponsors study.sponsors ]
                }
            , Tab.item
                { id = "tabStudyDocs"
                , link = Tab.link [] [ text studyDocsTabTitle ]
                , pane =
                    Tab.pane [ Spacing.mt3 ]
                        [ viewStudyDocs study.studyDocs ]
                }
            , Tab.item
                { id = "tabStudyOutcomes"
                , link = Tab.link [] [ text studyOutcomesTabTitle ]
                , pane =
                    Tab.pane [ Spacing.mt3 ]
                        [ viewStudyOutcomes study.studyOutcomes ]
                }
            ]
        |> Tab.view tabState


mkUl items =
    case List.length items of
        0 ->
            text ""

        _ ->
            ul [] (List.map (\item -> li [] [ text item ]) items)


viewStudy : Study -> Html Msg
viewStudy study =
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
                ]
        }


viewConditions : List Condition -> Html Msg
viewConditions conditions =
    case List.length conditions of
        0 ->
            text "None"

        _ ->
            mkUl (List.map (\c -> c.condition) conditions)


viewInterventions : List Intervention -> Html Msg
viewInterventions interventions =
    case List.length interventions of
        0 ->
            text "None"

        _ ->
            mkUl (List.map (\i -> i.intervention) interventions)


viewSponsors : List Sponsor -> Html Msg
viewSponsors sponsors =
    case List.length sponsors of
        0 ->
            text "None"

        _ ->
            mkUl (List.map (\s -> s.sponsorName) sponsors)


viewStudyDocs : List StudyDoc -> Html Msg
viewStudyDocs studyDocs =
    let
        viewUrl url =
            case String.left 4 url == "http" of
                True ->
                    a [ href url ] [ text url ]

                _ ->
                    text url

        mkTable doc =
            [ tr [ rowPrimary ]
                [ th [] [ text "DocId" ]
                , td [] [ text doc.docId ]
                ]
            , tr []
                [ th [] [ text "DocType" ]
                , td [] [ text doc.docType ]
                ]
            , tr []
                [ th [] [ text "URL" ]
                , td [] [ viewUrl doc.docUrl ]
                ]
            , tr []
                [ th [] [ text "Comment" ]
                , td [] [ text doc.docComment ]
                ]
            ]
    in
    case List.length studyDocs of
        0 ->
            text "None"

        _ ->
            table
                { options = []
                , thead = simpleThead []
                , tbody =
                    tbody [] (List.concat <| List.map mkTable studyDocs)
                }


viewStudyOutcomes : List StudyOutcome -> Html Msg
viewStudyOutcomes studyOutcomes =
    let
        mkTable outcome =
            [ tr [ rowPrimary ]
                [ th [] [ text "Outcome Type" ]
                , td [] [ text outcome.outcomeType ]
                ]
            , tr []
                [ th [] [ text "Measure" ]
                , td [] [ text outcome.measure ]
                ]
            , tr []
                [ th [] [ text "Time Frame" ]
                , td [] [ text outcome.timeFrame ]
                ]
            , tr []
                [ th [] [ text "Description" ]
                , td [] [ text outcome.description ]
                ]
            ]
    in
    table
        { options = []
        , thead = simpleThead []
        , tbody =
            tbody []
                (List.concat <| List.map mkTable studyOutcomes)
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
        |> Json.Decode.Pipeline.optional "study_outcomes"
            (Json.Decode.list decoderStudyOutcome)
            []
        |> Json.Decode.Pipeline.optional "study_docs"
            (Json.Decode.list decoderStudyDoc)
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


decoderStudyDoc : Decoder StudyDoc
decoderStudyDoc =
    Json.Decode.succeed StudyDoc
        |> Json.Decode.Pipeline.required "study_doc_id" int
        |> Json.Decode.Pipeline.required "doc_id" string
        |> Json.Decode.Pipeline.required "doc_type" string
        |> Json.Decode.Pipeline.required "doc_url" string
        |> Json.Decode.Pipeline.required "doc_comment" string


decoderStudyOutcome : Decoder StudyOutcome
decoderStudyOutcome =
    Json.Decode.succeed StudyOutcome
        |> Json.Decode.Pipeline.required "study_outcome_id" int
        |> Json.Decode.Pipeline.required "outcome_type" string
        |> Json.Decode.Pipeline.required "measure" string
        |> Json.Decode.Pipeline.required "time_frame" string
        |> Json.Decode.Pipeline.required "description" string


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
