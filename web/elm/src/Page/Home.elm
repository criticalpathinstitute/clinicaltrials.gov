module Page.Home exposing (Model, Msg, init, subscriptions, update, view)

import Bootstrap.Button as Button
import Bootstrap.Form as Form
import Bootstrap.Form.Checkbox as Checkbox
import Bootstrap.Form.Input as Input
import Bootstrap.Form.Select as Select
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Bootstrap.Table exposing (table, tbody, td, th, thead, tr)
import Common exposing (commify, viewHttpErrorMessage)
import Config exposing (apiServer)
import Debug
import File.Download as Download
import Html exposing (Html, a, br, div, h1, text)
import Html.Attributes exposing (class, for, href, value)
import Html.Events exposing (onInput, onSubmit)
import Http
import Json.Decode exposing (Decoder, field, float, int, nullable, string)
import Json.Decode.Pipeline exposing (hardcoded, optional, required)
import Regex
import RemoteData exposing (RemoteData, WebData)
import Route
import Task
import Url.Builder


type alias Model =
    { summary : WebData Summary
    , conditionFilter : Maybe String
    , conditionsDropDown : WebData (List ConditionDropDown)
    , searchResults : WebData (List Study)
    , queryText : Maybe String
    , querySelectedConditions : List String
    , queryDetailedDescription : Maybe String
    }


type alias ConditionDropDown =
    { conditionId : Int
    , condition : String
    , num_studies : Int
    }


type alias Summary =
    { num_studies : Int
    }


type alias Study =
    { nctId : String
    , title : String
    , detailedDescription : String
    }


type Msg
    = AddCondition String
    | ConditionDropDownResponse (WebData (List ConditionDropDown))
    | DoSearch
    | Download
    | RemoveCondition String
    | SummaryResponse (WebData Summary)
    | SetConditionFilter String
    | SetQueryDetailedDescription String
    | SetQueryText String
    | SearchResponse (WebData (List Study))


initialModel =
    { summary = RemoteData.NotAsked
    , conditionFilter = Nothing
    , conditionsDropDown = RemoteData.NotAsked
    , searchResults = RemoteData.NotAsked
    , queryText = Nothing
    , querySelectedConditions = []
    , queryDetailedDescription = Nothing
    }


init : ( Model, Cmd Msg )
init =
    ( initialModel, Cmd.batch [ getSummary, getConditionDropDown ] )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AddCondition condition ->
            let
                newCondition =
                    case String.length condition of
                        0 ->
                            []

                        _ ->
                            [ condition ]

                newModel =
                    { model
                        | querySelectedConditions =
                            model.querySelectedConditions ++ newCondition
                    }
            in
            ( newModel, doSearch newModel )

        ConditionDropDownResponse data ->
            ( { model | conditionsDropDown = data }
            , Cmd.none
            )

        DoSearch ->
            ( model, doSearch model )

        Download ->
            ( model, Download.url (searchUrl model True) )

        RemoveCondition condition ->
            let
                newConditions =
                    List.filter
                        (\c -> c /= condition)
                        model.querySelectedConditions

                newModel =
                    { model | querySelectedConditions = newConditions }
            in
            ( newModel, doSearch newModel )

        SummaryResponse data ->
            ( { model | summary = data }
            , Cmd.none
            )

        SearchResponse data ->
            ( { model | searchResults = data }
            , Cmd.none
            )

        SetConditionFilter text ->
            let
                newFilter =
                    case String.length text of
                        0 ->
                            Nothing

                        _ ->
                            Just (String.toLower text)
            in
            ( { model | conditionFilter = newFilter }
            , Cmd.none
            )

        SetQueryDetailedDescription desc ->
            let
                newDesc =
                    case String.length desc of
                        0 ->
                            Nothing

                        _ ->
                            Just desc

                newModel =
                    { model | queryDetailedDescription = newDesc }
            in
            ( newModel, doSearch newModel )

        SetQueryText query ->
            let
                newQuery =
                    case String.length query of
                        0 ->
                            Nothing

                        _ ->
                            Just query

                newModel =
                    { model | queryText = newQuery }
            in
            ( newModel, doSearch newModel )


view : Model -> Html Msg
view model =
    let
        summary =
            case model.summary of
                RemoteData.NotAsked ->
                    "Not asked"

                RemoteData.Loading ->
                    "Loading data..."

                RemoteData.Failure httpError ->
                    viewHttpErrorMessage httpError

                RemoteData.Success data ->
                    "Search " ++ commify data.num_studies ++ " studies"

        mkConditionSelect =
            let
                empty =
                    [ Select.item [ value "" ] [ text "--Select--" ] ]

                mkSelectItem condition =
                    Select.item [ value condition.condition ]
                        [ text <|
                            condition.condition
                                ++ " ("
                                ++ String.fromInt condition.num_studies
                                ++ ")"
                        ]

                filterConditions conditions =
                    let
                        regex =
                            case model.conditionFilter of
                                Just filter ->
                                    Just
                                        (Maybe.withDefault Regex.never
                                            (Regex.fromString filter)
                                        )

                                _ ->
                                    Nothing
                    in
                    case regex of
                        Just re ->
                            List.filter
                                (\c ->
                                    Regex.contains re
                                        (String.toLower c.condition)
                                )
                                conditions

                        _ ->
                            []

                mkSelect data =
                    case List.length data of
                        0 ->
                            text ""

                        _ ->
                            Select.select
                                [ Select.id "condition"
                                , Select.onChange AddCondition
                                ]
                                (empty ++ List.map mkSelectItem data)
            in
            case model.conditionsDropDown of
                RemoteData.Success data ->
                    mkSelect (filterConditions data)

                RemoteData.Failure httpError ->
                    text (viewHttpErrorMessage httpError)

                _ ->
                    text "Error fetching conditions"

        viewCondition condition =
            Button.button
                [ Button.outlinePrimary
                , Button.onClick (RemoveCondition condition)
                ]
                [ text (condition ++ " ⦻") ]

        viewSelectedConditions =
            List.map viewCondition model.querySelectedConditions

        searchForm =
            Form.form [ onSubmit DoSearch ]
                [ Form.label [] [ text summary ]
                , Form.group []
                    [ Form.label [ for "text" ] [ text "Text:" ]
                    , Input.text
                        [ Input.attrs [ onInput SetQueryText ] ]
                    ]

                --, Form.group []
                --    [ Form.label [ for "text" ] [ text "Detailed Description:" ]
                --    , Input.text
                --        [ Input.attrs [ onInput SetQueryDetailedDescription ] ]
                --    ]
                , Form.group []
                    ([ Form.label [ for "condition" ]
                        [ text "Condition:" ]
                     , Input.text
                        [ Input.attrs [ onInput SetConditionFilter ] ]
                     , mkConditionSelect
                     ]
                        ++ viewSelectedConditions
                    )
                ]

        results =
            case model.searchResults of
                RemoteData.NotAsked ->
                    div [] [ text "" ]

                RemoteData.Loading ->
                    div [] [ text "Loading..." ]

                RemoteData.Failure httpError ->
                    div [] [ text (viewHttpErrorMessage httpError) ]

                RemoteData.Success studies ->
                    let
                        mkRow study =
                            tr []
                                [ td []
                                    [ a
                                        [ Route.href
                                            (Route.Study study.nctId)
                                        ]
                                        [ text study.title ]
                                    , br [] []
                                    , text study.nctId
                                    , br [] []
                                    , text
                                        (truncate
                                            study.detailedDescription
                                            80
                                        )
                                    ]
                                ]

                        numStudies =
                            List.length studies

                        title =
                            "Search Results (" ++ commify numStudies ++ ")"

                        resultsDiv =
                            case numStudies of
                                0 ->
                                    []

                                _ ->
                                    [ h1 [] [ text title ]
                                    , Button.button
                                        [ Button.outlinePrimary
                                        , Button.onClick Download
                                        ]
                                        [ text "Download" ]
                                    , table
                                        { options =
                                            [ Bootstrap.Table.striped ]
                                        , thead = thead [] []
                                        , tbody =
                                            tbody []
                                                (List.map mkRow studies)
                                        }
                                    ]
                    in
                    div [] resultsDiv
    in
    Grid.container []
        [ Grid.row [ Row.centerMd ]
            [ Grid.col [ Col.mdAuto ] [ searchForm ]
            ]
        , Grid.row []
            [ Grid.col [] [ results ]
            ]
        ]


getSummary : Cmd Msg
getSummary =
    let
        url =
            apiServer ++ "/summary"
    in
    Http.get
        { url = url
        , expect =
            Http.expectJson
                (RemoteData.fromResult >> SummaryResponse)
                decoderSummary
        }


getConditionDropDown : Cmd Msg
getConditionDropDown =
    let
        url =
            apiServer ++ "/conditions"
    in
    Http.get
        { url = url
        , expect =
            Http.expectJson
                (RemoteData.fromResult >> ConditionDropDownResponse)
                (Json.Decode.list decoderConditionDropDown)
        }


searchUrl : Model -> Bool -> String
searchUrl model downloadCsv =
    let
        builder ( label, value ) =
            case value of
                Just v ->
                    Just (Url.Builder.string label v)

                _ ->
                    Nothing

        conditions =
            case List.length model.querySelectedConditions of
                0 ->
                    Nothing

                _ ->
                    Just (String.join "::" model.querySelectedConditions)

        downloadFlag =
            case downloadCsv of
                True ->
                    Just "1"

                _ ->
                    Nothing

        queryParams =
            Url.Builder.toQuery <|
                List.filterMap builder
                    [ ( "text"
                      , model.queryText
                      )

                    --, ( "detailed_description"
                    --  , model.queryDetailedDescription
                    --  )
                    , ( "conditions"
                      , conditions
                      )
                    , ( "download"
                      , downloadFlag
                      )
                    ]
    in
    apiServer ++ "/search/" ++ queryParams


doSearch : Model -> Cmd Msg
doSearch model =
    Http.get
        { url = searchUrl model False
        , expect =
            Http.expectJson
                (RemoteData.fromResult >> SearchResponse)
                (Json.Decode.list decoderStudy)
        }


truncate : String -> Int -> String
truncate text max =
    case String.length text <= (max - 3) of
        True ->
            text

        _ ->
            String.left (max - 3) text ++ "..."


decoderConditionDropDown : Decoder ConditionDropDown
decoderConditionDropDown =
    Json.Decode.succeed ConditionDropDown
        |> Json.Decode.Pipeline.required "condition_id" int
        |> Json.Decode.Pipeline.required "condition" string
        |> Json.Decode.Pipeline.required "num_studies" int


decoderSummary : Decoder Summary
decoderSummary =
    Json.Decode.succeed Summary
        |> Json.Decode.Pipeline.required "num_studies" int


decoderStudy : Decoder Study
decoderStudy =
    Json.Decode.succeed Study
        |> Json.Decode.Pipeline.required "nct_id" string
        |> Json.Decode.Pipeline.required "title" string
        |> Json.Decode.Pipeline.optional "detailed_description" string ""


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
