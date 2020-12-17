module Page.Home exposing (Model, Msg, init, subscriptions, update, view)

import Bootstrap.Button as Button
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Bootstrap.Table exposing (table, tbody, td, th, thead, tr)
import Common exposing (commify, viewHttpErrorMessage)
import Config exposing (apiServer)
import Debug
import Html exposing (Html, a, div, h1, text)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onSubmit)
import Http
import Json.Decode exposing (Decoder, field, float, int, nullable, string)
import Json.Decode.Pipeline exposing (hardcoded, optional, required)
import RemoteData exposing (RemoteData, WebData)
import Route
import Url.Builder


type alias Model =
    { summary : WebData Summary
    , query : Maybe String
    , searchResults : WebData (List Study)
    }


type alias Summary =
    { num_studies : Int
    }


type alias Study =
    { nctId : String
    , title : String
    }


type Msg
    = SummaryResponse (WebData Summary)
    | SetQuery String
    | SearchResponse (WebData (List Study))
    | DoSearch


init : ( Model, Cmd Msg )
init =
    ( { summary = RemoteData.NotAsked
      , query = Nothing
      , searchResults = RemoteData.NotAsked
      }
    , Cmd.batch [ getSummary ]
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DoSearch ->
            ( model, doSearch model.query )

        SummaryResponse data ->
            ( { model | summary = data }
            , Cmd.none
            )

        SearchResponse data ->
            ( { model | searchResults = data }
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
                    "Search " ++ commify data.num_studies ++ " studies:"

        hasQuery =
            case model.query of
                Just qry ->
                    String.length qry > 0

                _ ->
                    False

        searchForm =
            Form.formInline [ onSubmit DoSearch ]
                [ Form.label [] [ text summary ]
                , Input.text
                    [ Input.attrs [ onInput SetQuery ] ]
                , Button.submitButton
                    [ Button.primary
                    , Button.disabled (not hasQuery)
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


doSearch : Maybe String -> Cmd Msg
doSearch query =
    case query of
        Just term ->
            let
                url =
                    apiServer ++ "/search/" ++ term
            in
            Http.get
                { url = url
                , expect =
                    Http.expectJson
                        (RemoteData.fromResult >> SearchResponse)
                        (Json.Decode.list decoderStudy)
                }

        _ ->
            Cmd.none


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
