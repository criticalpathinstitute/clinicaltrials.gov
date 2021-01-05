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
import Html exposing (Html, a, div, h1, text)
import Html.Attributes exposing (class, for, value)
import Html.Events exposing (onInput, onSubmit)
import Http
import Json.Decode exposing (Decoder, field, float, int, nullable, string)
import Json.Decode.Pipeline exposing (hardcoded, optional, required)
import Regex
import RemoteData exposing (RemoteData, WebData)
import Route
import Url.Builder


type alias Model =
    { summary : WebData Summary
    , query : Maybe String
    , selectedConditions : List String
    , conditionFilter : Maybe String
    , conditionsDropDown : WebData (List ConditionDropDown)
    , searchResults : WebData (List Study)
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
    }


type Msg
    = ConditionDropDownResponse (WebData (List ConditionDropDown))
    | RemoveCondition String
    | SummaryResponse (WebData Summary)
    | SetCondition String
    | SetConditionFilter String
    | SetQuery String
    | SearchResponse (WebData (List Study))
    | DoSearch


init : ( Model, Cmd Msg )
init =
    ( { summary = RemoteData.NotAsked
      , query = Nothing
      , selectedConditions = []
      , conditionFilter = Nothing
      , conditionsDropDown = RemoteData.NotAsked
      , searchResults = RemoteData.NotAsked
      }
    , Cmd.batch [ getSummary, getConditionDropDown ]
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ConditionDropDownResponse data ->
            ( { model | conditionsDropDown = data }
            , Cmd.none
            )

        DoSearch ->
            ( model, doSearch model )

        RemoveCondition condition ->
            let
                newConditions =
                    List.filter
                        (\c -> c /= condition)
                        model.selectedConditions
            in
            ( { model | selectedConditions = newConditions }, Cmd.none )

        SummaryResponse data ->
            ( { model | summary = data }
            , Cmd.none
            )

        SearchResponse data ->
            ( { model | searchResults = data }
            , Cmd.none
            )

        SetCondition condition ->
            let
                newCondition =
                    case String.length condition of
                        0 ->
                            []

                        _ ->
                            [ condition ]
            in
            ( { model
                | selectedConditions = model.selectedConditions ++ newCondition
              }
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

        SetQuery query ->
            let
                newQuery =
                    case String.length query of
                        0 ->
                            Nothing

                        _ ->
                            Just query
            in
            ( { model | query = newQuery }
            , Cmd.none
            )


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
                                [ Select.id "condition", Select.onChange SetCondition ]
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
                [ text (condition ++ " [X]") ]

        viewSelectedConditions =
            List.map viewCondition model.selectedConditions

        searchForm =
            Form.form [ onSubmit DoSearch ]
                [ Form.label [] [ text summary ]
                , Form.group []
                    [ Form.label [ for "text" ] [ text "Text" ]
                    , Input.text
                        [ Input.attrs [ onInput SetQuery ] ]
                    ]
                , Form.group []
                    ([ Form.label [ for "condition" ]
                        [ text "Condition" ]
                     , Input.text
                        [ Input.attrs [ onInput SetConditionFilter ] ]
                     , mkConditionSelect
                     ]
                        ++ viewSelectedConditions
                    )
                , Button.submitButton
                    [ Button.primary
                    , Button.attrs [ class "ml-sm-2 my-2" ]
                    ]
                    [ text "Go" ]
                ]

        results =
            case model.searchResults of
                RemoteData.NotAsked ->
                    div [] [ text "" ]

                RemoteData.Loading ->
                    div [] [ text "Searching..." ]

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
                                    ]
                                ]

                        numStudies =
                            List.length studies

                        title =
                            "Search Results (" ++ commify numStudies ++ ")"
                    in
                    div []
                        [ h1 [] [ text title ]
                        , table
                            { options = [ Bootstrap.Table.striped ]
                            , thead = thead [] []
                            , tbody = tbody [] (List.map mkRow studies)
                            }
                        ]
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


doSearch : Model -> Cmd Msg
doSearch model =
    let
        builder ( label, value ) =
            case value of
                Just v ->
                    Just (Url.Builder.string label v)

                _ ->
                    Nothing

        conditions =
            case List.length model.selectedConditions of
                0 ->
                    Nothing

                _ ->
                    Just (String.join "::" model.selectedConditions)

        queryParams =
            Url.Builder.toQuery <|
                List.filterMap builder
                    [ ( "text"
                      , model.query
                      )
                    , ( "conditions"
                      , conditions
                      )
                    ]

        url =
            case String.length queryParams of
                0 ->
                    Nothing

                _ ->
                    Just <| apiServer ++ "/search/" ++ queryParams
    in
    case url of
        Just someUrl ->
            Http.get
                { url = someUrl
                , expect =
                    Http.expectJson
                        (RemoteData.fromResult >> SearchResponse)
                        (Json.Decode.list decoderStudy)
                }

        _ ->
            Cmd.none


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


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
